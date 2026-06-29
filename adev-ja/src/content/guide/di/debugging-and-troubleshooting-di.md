# 依存性の注入のデバッグとトラブルシューティング

依存性の注入（DI）の問題は、通常、構成ミス、スコープの問題、または誤った使用パターンから発生します。このガイドでは、開発者が遭遇しやすい一般的なDIの問題を特定し、解決する方法を説明します。

## よくある落とし穴と解決策 {#common-pitfalls-and-solutions}

### 期待した場所でサービスを利用できない {#services-not-available-where-expected}

もっとも一般的なDIの問題の1つは、サービスを注入しようとしたものの、Angularが現在のインジェクターや親インジェクターのいずれからもそのサービスを見つけられない場合に発生します。これは通常、サービスが誤ったスコープで提供されているか、まったく提供されていない場合に起こります。

#### プロバイダースコープの不一致 {#provider-scope-mismatch}

コンポーネントの`providers`配列でサービスを提供すると、Angularはそのコンポーネントのインジェクターにインスタンスを作成します。このインスタンスは、そのコンポーネントと子コンポーネントでのみ利用できます。親コンポーネントや兄弟コンポーネントは異なるインジェクターを使用するため、このインスタンスにはアクセスできません。

```angular-ts {header: 'child-view.ts'}
import {Component} from '@angular/core';
import {DataStore} from './data-store';

@Component({
  selector: 'app-child',
  template: '<p>Child</p>',
  providers: [DataStore], // Only available in this component and its children
})
export class ChildView {}
```

```angular-ts {header: 'parent-view.ts'}
import {Component, inject} from '@angular/core';
import {DataStore} from './data-store';

@Component({
  selector: 'app-parent',
  template: '<app-child />',
})
export class ParentView {
  private dataService = inject(DataStore); // ERROR: Not available to parent
}
```

Angularは階層を上方向にのみ検索し、下方向には検索しません。親コンポーネントは、子コンポーネントで提供されたサービスにアクセスできません。

**解決策:** サービスをより上位のレベル（アプリケーションまたは親コンポーネント）で提供します。

```ts {prefer}
import {Service} from '@angular/core';

@Service()
export class DataStore {
  // Available everywhere
}
```

TIP: `@Service`はサービスをどこからでも利用可能にし、ツリーシェイクを有効にします。アプリケーション全体にスコープしたくない場合は、`autoProvided: false`を指定してください。

#### サービスと遅延読み込みルート {#services-and-lazy-loaded-routes}

遅延読み込みルートの`providers`配列でサービスを提供すると、Angularはそのルート用の子インジェクターを作成します。このインジェクターとそのサービスは、ルートが読み込まれた後にのみ利用可能になります。アプリケーション内で即時読み込みされる部分のコンポーネントは、遅延読み込みインジェクターが作成される前から存在する別のインジェクターを使用するため、これらのサービスにアクセスできません。

```ts {header: 'feature.routes.ts'}
import {Routes} from '@angular/router';
import {FeatureClient} from './feature-client';

export const featureRoutes: Routes = [
  {
    path: 'feature',
    providers: [FeatureClient],
    loadComponent: () => import('./feature-view'),
  },
];
```

```angular-ts {header: 'eager-view.ts'}
import {Component, inject} from '@angular/core';
import {FeatureClient} from './feature-client';

@Component({
  selector: 'app-eager',
  template: '<p>Eager Component</p>',
})
export class EagerView {
  private featureService = inject(FeatureClient); // ERROR: Not available yet
}
```

遅延読み込みルートは、ルートの読み込み後にのみ利用できる子インジェクターを作成します。

NOTE: デフォルトでは、ルートインジェクターとそのサービスは、そのルートから離れた後も保持されます。これらはアプリケーションが閉じられるまで破棄されません。未使用のルートインジェクターの自動クリーンアップについては、[ルートの振る舞いのカスタマイズ](guide/routing/customizing-route-behavior#experimental-automatic-cleanup-of-unused-route-injectors)を参照してください。

**解決策:** 遅延読み込みの境界をまたいで共有する必要があるサービスには、`@Service`を使用します。

```ts {prefer, header: 'Provide at root for shared services'}
import {Service} from '@angular/core';

@Service()
export class FeatureClient {
  // Available everywhere, including before lazy load
}
```

サービスを遅延読み込みしつつ即時読み込みコンポーネントでも利用したい場合は、必要な場所でのみ注入し、オプション注入を使用して利用可否を扱います。

### シングルトンではなく複数のインスタンスになる {#multiple-instances-instead-of-singletons}

共有された1つのインスタンス（シングルトン）を期待しているのに、異なるコンポーネントで別々のインスタンスを取得してしまう場合があります。

#### ルートではなくコンポーネントで提供している {#providing-in-component-instead-of-root}

コンポーネントの`providers`配列にサービスを追加すると、Angularはそのコンポーネントの各インスタンスごとにサービスの新しいインスタンスを作成します。各コンポーネントは独自の個別サービスインスタンスを取得するため、あるコンポーネントでの変更は他のコンポーネントのサービスインスタンスには影響しません。アプリケーション全体で状態を共有したい場合、これは多くの場合で想定外の挙動です。

```angular-ts {avoid, header: 'Component-level provider creates multiple instances'}
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-profile',
  template: '<p>Profile</p>',
  providers: [UserClient], // Creates new instance per component!
})
export class UserProfile {
  private userService = inject(UserClient);
}

@Component({
  selector: 'app-settings',
  template: '<p>Settings</p>',
  providers: [UserClient], // Different instance!
})
export class UserSettings {
  private userService = inject(UserClient);
}
```

各コンポーネントは独自の`UserClient`インスタンスを取得します。あるコンポーネントでの変更は、もう一方には影響しません。

**解決策:** シングルトンには`@Service`を使用します。

```ts {prefer, header: 'Root-level singleton'}
import {Injectable} from '@angular/core';

@Service()
export class UserClient {
  // Single instance shared across all components
}
```

#### 複数のインスタンスが意図的な場合 {#when-multiple-instances-are-intentional}

コンポーネント固有の状態のために、コンポーネントごとに別々のインスタンスが必要な場合もあります。

```angular-ts {header: 'Intentional: Component-scoped state'}
import {Injectable, signal} from '@angular/core';

@Injectable() // No providedIn - must be provided explicitly
export class FormStateStore {
  private formData = signal({});

  setData(data: any) {
    this.formData.set(data);
  }

  getData() {
    return this.formData();
  }
}

@Component({
  selector: 'app-user-form',
  template: '<form>...</form>',
  providers: [FormStateStore], // Each form gets its own state
})
export class UserForm {
  private formState = inject(FormStateStore);
}
```

このパターンは次の用途に役立ちます。

- フォーム状態の管理（各フォームが分離された状態を持つ）
- コンポーネント固有のキャッシュ
- 共有すべきではない一時データ

### inject()の誤った使用 {#incorrect-inject-usage}

`inject()`関数は、クラスの構築中やファクトリの実行中など、特定のコンテキストでのみ機能します。

#### ライフサイクルフックでinject()を使用する {#using-inject-in-lifecycle-hooks}

`ngOnInit()`、`ngAfterViewInit()`、`ngOnDestroy()`のようなライフサイクルフック内で`inject()`関数を呼び出すと、これらのメソッドは注入コンテキストの外で実行されるため、Angularはエラーをスローします。注入コンテキストは、ライフサイクルフックが呼び出される前に行われる、クラス構築の同期的な実行中にのみ利用できます。

```angular-ts {avoid, header: 'inject() in ngOnInit'}
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-profile',
  template: '<p>User: {{userName}}</p>',
})
export class UserProfile {
  userName = '';

  ngOnInit() {
    const userService = inject(UserClient); // ERROR: Not an injection context
    this.userName = userService.getUser().name;
  }
}
```

**解決策:** 依存性を取得し、フィールド初期化子で値を派生させます。

```angular-ts {prefer, header: 'Derive values in field initializers'}
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-profile',
  template: '<p>User: {{userName}}</p>',
})
export class UserProfile {
  private userService = inject(UserClient);
  userName = this.userService.getUser().name;
}
```

#### 遅延注入にInjectorを使用する {#using-the-injector-for-deferred-injection}

注入コンテキストの外でサービスを取得する必要がある場合は、取得済みの`Injector`を`injector.get()`で直接使用します。

```angular-ts
import {Component, inject, Injector} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-profile',
  template: '<button (click)="delayedLoad()">Load Later</button>',
})
export class UserProfile {
  private injector = inject(Injector);

  delayedLoad() {
    setTimeout(() => {
      const userService = this.injector.get(UserClient);
      console.log(userService.getUser());
    }, 1000);
  }
}
```

#### コールバックでrunInInjectionContextを使用する {#using-runininjectioncontext-for-callbacks}

**他のコード**が`inject()`を呼び出せるようにする必要がある場合は、`runInInjectionContext()`を使用します。これは、依存性の注入を使用する可能性があるコールバックを受け取る場合に役立ちます。

```angular-ts
import {Component, inject, Injector, input} from '@angular/core';

@Component({
  selector: 'app-data-loader',
  template: '<button (click)="load()">Load</button>',
})
export class DataLoader {
  private injector = inject(Injector);
  onLoad = input<() => void>();

  load() {
    const callback = this.onLoad();
    if (callback) {
      // Enable the callback to use inject()
      this.injector.runInInjectionContext(callback);
    }
  }
}
```

`runInInjectionContext()`メソッドは一時的な注入コンテキストを作成し、コールバック内のコードが`inject()`を呼び出せるようにします。

IMPORTANT: 可能な限り、常にクラスレベルで依存性を取得してください。単純な遅延取得には`injector.get()`を使用し、外部コードが`inject()`を呼び出す必要がある場合にのみ`runInInjectionContext()`を使用してください。

TIP: コードが有効な注入コンテキストで実行されていることを確認するには、`assertInInjectionContext()`を使用します。これは、`inject()`を呼び出す再利用可能な関数を作成するときに役立ちます。詳細は[コンテキストのアサート](guide/di/dependency-injection-context#asserts-the-context)を参照してください。

### providersとviewProvidersの混同 {#providers-vs-viewproviders-confusion}

`providers`と`viewProviders`の違いは、コンテンツ投影のシナリオに影響します。

#### 違いを理解する {#understanding-the-difference}

**providers:** コンポーネントのテンプレートと、コンポーネントに投影された任意のコンテンツ（ng-content）の両方で利用できます。

**viewProviders:** コンポーネントのテンプレートでのみ利用でき、投影されたコンテンツでは利用できません。

```angular-ts {header: 'parent-view.ts'}
import {Component, inject} from '@angular/core';
import {ThemeStore} from './theme-store';

@Component({
  selector: 'app-parent',
  template: `
    <div>
      <p>Theme: {{ themeService.theme() }}</p>
      <ng-content />
    </div>
  `,
  providers: [ThemeStore], // Available to content children
})
export class ParentView {
  protected themeService = inject(ThemeStore);
}

@Component({
  selector: 'app-parent-view',
  template: `
    <div>
      <p>Theme: {{ themeService.theme() }}</p>
      <ng-content />
    </div>
  `,
  viewProviders: [ThemeStore], // NOT available to content children
})
export class ParentViewOnly {
  protected themeService = inject(ThemeStore);
}
```

```angular-ts {header: 'child-view.ts'}
import {Component, inject} from '@angular/core';
import {ThemeStore} from './theme-store';

@Component({
  selector: 'app-child',
  template: '<p>Child theme: {{theme()}}</p>',
})
export class ChildView {
  private themeService = inject(ThemeStore, {optional: true});
  theme = () => this.themeService?.theme() ?? 'none';
}
```

```angular-ts {header: 'app.ts'}
@Component({
  selector: 'app-root',
  template: `
    <app-parent>
      <app-child />
      <!-- Can access ThemeStore -->
    </app-parent>

    <app-parent-view>
      <app-child />
      <!-- Cannot access ThemeStore -->
    </app-parent-view>
  `,
})
export class App {}
```

**`app-parent`に投影された場合:** `providers`によって投影されたコンテンツで利用可能になるため、子コンポーネントは`ThemeStore`を注入できます。

**`app-parent-view`に投影された場合:** `viewProviders`が親のテンプレートのみに制限するため、子コンポーネントは`ThemeStore`を注入できません。

#### providersとviewProvidersの選択 {#choosing-between-providers-and-viewproviders}

次の場合は`providers`を使用します。

- サービスを投影されたコンテンツで利用可能にしたい
- コンテンツ子にサービスへアクセスさせたい
- 汎用サービスを提供している

次の場合は`viewProviders`を使用します。

- サービスをコンポーネントのテンプレートだけで利用可能にしたい
- 投影されたコンテンツから実装の詳細を隠したい
- 外部へ漏れるべきではない内部サービスを提供している

**デフォルトの推奨:** `viewProviders`でアクセスを制限する具体的な理由がない限り、`providers`を使用してください。

### InjectionTokenの問題 {#injectiontoken-issues}

クラス以外の依存性に`InjectionToken`を使用するとき、開発者はトークンの同一性、型安全性、プロバイダー構成に関する問題に遭遇することがよくあります。これらの問題は通常、JavaScriptがオブジェクト同一性を扱う方法と、TypeScriptが型を推論する方法に起因します。

#### トークン同一性の混乱 {#token-identity-confusion}

新しい`InjectionToken`インスタンスを作成すると、JavaScriptはメモリ内に一意のオブジェクトを作成します。まったく同じ説明文字列を持つ別の`InjectionToken`を作成しても、それは完全に別のオブジェクトです。Angularはプロバイダーと注入ポイントを一致させるために、トークンオブジェクトの同一性（説明ではありません）を使用するため、同じ説明でもオブジェクト同一性が異なるトークンは互いの値にアクセスできません。

```ts {header: 'config.token.ts'}
import {InjectionToken} from '@angular/core';

export interface AppConfig {
  apiUrl: string;
}

export const APP_CONFIG = new InjectionToken<AppConfig>('app config');
```

```ts {header: 'app.config.ts'}
import {APP_CONFIG} from './config.token';

export const appConfig: AppConfig = {
  apiUrl: 'https://api.example.com',
};

bootstrapApplication(App, {
  providers: [{provide: APP_CONFIG, useValue: appConfig}],
});
```

```angular-ts {avoid, header: 'feature-view.ts'}
// Creating new token with same description
import {InjectionToken, inject} from '@angular/core';
import {AppConfig} from './config.token';

const APP_CONFIG = new InjectionToken<AppConfig>('app config');

@Component({
  selector: 'app-feature',
  template: '<p>Feature</p>',
})
export class FeatureView {
  private config = inject(APP_CONFIG); // ERROR: Different token instance!
}
```

両方のトークンが`'app config'`という説明を持っていても、それらは異なるオブジェクトです。Angularは説明ではなく参照によってトークンを比較します。

**解決策:** 同じトークンインスタンスをインポートします。

```angular-ts {prefer, header: 'feature-view.ts'}
import {inject} from '@angular/core';
import {APP_CONFIG, AppConfig} from './config.token';

@Component({
  selector: 'app-feature',
  template: '<p>API: {{config.apiUrl}}</p>',
})
export class FeatureView {
  protected config = inject(APP_CONFIG); // Works: Same token instance
}
```

TIP: 常に共有ファイルからトークンをエクスポートし、必要な場所すべてでそれをインポートしてください。同じ説明を持つ複数の`InjectionToken`インスタンスを作成しないでください。

#### インターフェースを注入しようとする {#trying-to-inject-interfaces}

TypeScriptインターフェースを定義すると、それは型チェックのためにコンパイル中だけ存在します。TypeScriptはJavaScriptへコンパイルするときにすべてのインターフェース定義を消去するため、ランタイムにはAngularが注入トークンとして使用できるオブジェクトがありません。インターフェース型を注入しようとしても、Angularにはプロバイダー構成と照合する対象がありません。

```angular-ts {avoid, header: 'Can't inject interface'}
interface UserConfig {
  name: string;
  email: string;
}

@Component({
  selector: 'app-profile',
  template: '<p>Profile</p>',
})
export class UserProfile {
  // ERROR: Interfaces don't exist at runtime
  constructor(private config: UserConfig) {}
}
```

**解決策:** インターフェース型には`InjectionToken`を使用します。

```angular-ts {prefer, header: 'Use InjectionToken for interfaces'}
import {InjectionToken, inject} from '@angular/core';

interface UserConfig {
  name: string;
  email: string;
}

export const USER_CONFIG = new InjectionToken<UserConfig>('user configuration');

// Provide the configuration
bootstrapApplication(App, {
  providers: [
    {
      provide: USER_CONFIG,
      useValue: {name: 'Alice', email: 'alice@example.com'},
    },
  ],
});

// Inject using the token
@Component({
  selector: 'app-profile',
  template: '<p>User: {{config.name}}</p>',
})
export class UserProfile {
  protected config = inject(USER_CONFIG);
}
```

`InjectionToken`はランタイムに存在し、注入に使用できます。一方、`UserConfig`インターフェースは開発中の型安全性を提供します。

### 循環依存 {#circular-dependencies}

循環依存は、サービスが互いを注入し、Angularが解決できない循環を作る場合に発生します。詳細な説明とコード例については、[NG0200: Circular dependency](errors/NG0200)を参照してください。

**解決戦略**（推奨順）:

1. **再構成** - 共有ロジックを第3のサービスに抽出し、循環を断ち切ります
2. **イベントを使用** - 直接の依存を、`Subject`などのイベントベースの通信に置き換えます
3. **遅延注入** - `Injector.get()`を使用して一方の依存性を遅延させます（最後の手段）

NOTE: サービスの循環依存に`forwardRef()`を使用しないでください。これはスタンドアロンコンポーネント構成での循環インポートだけを解決します。

## 依存解決のデバッグ {#debugging-dependency-resolution}

### 解決プロセスを理解する {#understanding-the-resolution-process}

Angularはインジェクター階層を上にたどることで依存性を解決します。`NullInjectorError`が発生した場合、この検索順序を理解していると、不足しているプロバイダーをどこに追加すべきかを特定しやすくなります。

Angularは次の順序で検索します。

1. **要素インジェクター** - 現在のコンポーネントまたはディレクティブ
2. **親要素インジェクター** - 親コンポーネントを通じてDOMツリーを上にたどる
3. **環境インジェクター** - ルートまたはアプリケーションのインジェクター
4. **NullInjector** - 見つからない場合に`NullInjectorError`をスローします

`NullInjectorError`が表示された場合、そのサービスはコンポーネントがアクセスできるどのレベルでも提供されていません。次を確認してください。

- サービスに`@Service()`がある、または
- サービスに`@Injectable({providedIn: 'root'})`がある、または
- サービスがコンポーネントから到達できる`providers`配列に含まれている

この検索動作は、`self`、`skipSelf`、`host`、`optional`のような解決修飾子で変更できます。解決ルールと修飾子の完全な説明については、[階層型インジェクターガイド](guide/di/hierarchical-dependency-injection)を参照してください。

### Angular DevToolsを使用する {#using-angular-devtools}

Angular DevToolsには、インジェクター階層全体を可視化し、各レベルで利用できるプロバイダーを表示するインジェクターツリーインスペクターが含まれています。インストールと一般的な使い方については、[Angular DevToolsインジェクタードキュメント](tools/devtools/injectors)を参照してください。

DIの問題をデバッグするときは、DevToolsを使用して次の問いに答えます。

- **サービスは提供されていますか？** 注入に失敗しているコンポーネントを選択し、そのサービスがInjectorセクションに表示されるか確認します。
- **どのレベルですか？** コンポーネントツリーを上にたどり、そのサービスが実際に提供されている場所（コンポーネント、ルート、アプリケーションレベル）を見つけます。
- **複数のインスタンスですか？** シングルトンサービスが複数のコンポーネントインジェクターに表示される場合、`@Service`や`providedIn: 'root'`ではなく、コンポーネントの`providers`配列で提供されている可能性があります。

サービスがどのインジェクターにも表示されない場合は、`@Service`デコレーターがあるか、`providers`配列に列挙されていることを確認します。

### 注入のログ出力とトレース {#logging-and-tracing-injection}

DevToolsだけでは不十分な場合は、ログ出力を使用して注入の振る舞いをトレースします。

#### サービス作成をログ出力する {#logging-service-creation}

サービスがいつ作成されるかを確認するには、サービスコンストラクターにコンソールログを追加します。

```ts
import {Service} from '@angular/core';

@Service()
export class UserClient {
  constructor() {
    console.log('UserClient created');
    console.trace(); // Shows call stack
  }

  getUser() {
    return {name: 'Alice'};
  }
}
```

サービスが作成されると、ログメッセージと、注入がどこで発生したかを示すスタックトレースが表示されます。

**確認すべきこと:**

- コンストラクターは何回呼び出されていますか？（シングルトンなら1回のはずです）
- コード内のどこで注入されていますか？（スタックトレースを確認します）
- 期待したタイミングで作成されていますか？（アプリケーション起動時、または遅延時）

#### サービスの利用可否を確認する {#checking-service-availability}

サービスが利用可能かどうかを判断するには、ログ出力とともにオプション注入を使用します。

```angular-ts
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-debug',
  template: '<p>Debug Component</p>',
})
export class DebugView {
  private userService = inject(UserClient, {optional: true});

  constructor() {
    if (this.userService) {
      console.log('UserClient available:', this.userService);
    } else {
      console.warn('UserClient NOT available');
      console.trace(); // Shows where we tried to inject
    }
  }
}
```

このパターンにより、アプリケーションをクラッシュさせずにサービスが利用可能かを確認できます。

#### 解決修飾子をログ出力する {#logging-resolution-modifiers}

ログ出力を使って、異なる解決戦略をテストします。

```angular-ts
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-debug',
  template: '<p>Debug Component</p>',
  providers: [UserClient],
})
export class DebugView {
  // Try to get local instance
  private localService = inject(UserClient, {self: true, optional: true});

  // Try to get parent instance
  private parentService = inject(UserClient, {
    skipSelf: true,
    optional: true,
  });

  constructor() {
    console.log('Local instance:', this.localService);
    console.log('Parent instance:', this.parentService);
    console.log('Same instance?', this.localService === this.parentService);
  }
}
```

これにより、異なるインジェクターレベルでどのインスタンスが利用可能かがわかります。

### デバッグワークフロー {#debugging-workflow}

DIが失敗した場合は、次の体系的なアプローチに従います。

**ステップ1: エラーメッセージを読む**

- エラーコード（NG0200、NG0203など）を特定する
- 依存パスを読む
- どのトークンが失敗したかを確認する

**ステップ2: 基本を確認する**

- サービスに`@Service`または`@Injectable()`がありますか？
- `@Injectable`を使用している場合、`providedIn`は正しく設定されていますか？
- インポートは正しいですか？
- ファイルはコンパイル対象に含まれていますか？

**ステップ3: 注入コンテキストを確認する**

- `inject()`は有効なコンテキストで呼び出されていますか？
- 非同期の問題（await、setTimeout、promise）を確認する
- タイミングを確認する（破棄後ではないか）

**ステップ4: デバッグツールを使用する**

- Angular DevToolsを開く
- インジェクター階層を確認する
- コンストラクターにコンソールログを追加する
- オプション注入を使用して利用可否をテストする

**ステップ5: 単純化して切り分ける**

- 依存性を1つずつ削除する
- 最小限のコンポーネントでテストする
- 各インジェクターレベルを個別に確認する
- 再現ケースを作成する

## DIエラーリファレンス {#di-error-reference}

このセクションでは、遭遇する可能性のある特定のAngular DIエラーコードについて詳しく説明します。コンソールでこれらのエラーを見たときのリファレンスとして使用してください。

### NullInjectorError: No provider for [Service] {#nullinjectorerror-no-provider-for-service}

**エラーコード:** なし（`NullInjectorError`として表示されます）

このエラーは、Angularがインジェクター階層内でトークンのプロバイダーを見つけられない場合に発生します。エラーメッセージには、どこで注入が試行されたかを示す依存パスが含まれます。

```
NullInjectorError: No provider for UserClient!
  Dependency path: App -> AuthClient -> UserClient
```

依存パスは、`App`が`AuthClient`を注入し、それが`UserClient`を注入しようとしたものの、プロバイダーが見つからなかったことを示しています。

#### `@Service`または`@Injectable`デコレーターがない {#missing-the-service-or-injectable-decorator}

もっとも一般的な原因は、サービスクラスに`@Service`または`@Injectable()`デコレーターを付け忘れることです。

```ts {avoid, header: 'Missing decorator'}
export class UserClient {
  getUser() {
    return {name: 'Alice'};
  }
}
```

Angularでは、依存性の注入に必要なメタデータを生成するために`@Service()`デコレーターが必要です。

```ts {prefer, header: 'Include @Service'}
import {Service} from '@angular/core';

@Service()
export class UserClient {
  getUser() {
    return {name: 'Alice'};
  }
}
```

NOTE: 引数なしコンストラクターを持つクラスは`@Service()`なしでも動作することがありますが、これは推奨されません。一貫性を保ち、後で依存性を追加したときの問題を避けるため、常にデコレーターを含めてください。

#### providedIn構成がない {#missing-providedin-configuration}

サービスに`@Injectable()`があっても、どこで提供されるべきかを指定していない場合があります。

```ts {avoid, header: 'No providedIn specified'}
import {Injectable} from '@angular/core';

@Injectable()
export class UserClient {
  getUser() {
    return {name: 'Alice'};
  }
}
```

アプリケーション全体でサービスを利用可能にするには、`@Service`デコレーターを使用します。

```ts {prefer, header: 'Specify providedIn'}
import {Service} from '@angular/core';

@Service()
export class UserClient {
  getUser() {
    return {name: 'Alice'};
  }
}
```

`@Service`デコレーターはサービスをアプリケーション全体で利用可能にし、ツリーシェイクを有効にします（サービスが一度も注入されない場合はバンドルから削除されます）。

#### スタンドアロンコンポーネントのインポート不足 {#standalone-component-missing-imports}

Angular v20以降のスタンドアロンコンポーネントでは、各コンポーネントで依存性を明示的にインポートまたは提供する必要があります。

```angular-ts {avoid, header: 'Missing service import'}
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-profile',
  template: '<p>User: {{user().name}}</p>',
})
export class UserProfile {
  private userService = inject(UserClient); // ERROR: No provider
  user = this.userService.getUser();
}
```

サービスが`@Service`を使用していることを確認するか、コンポーネントの`providers`配列に追加してください。

```angular-ts {prefer, header: 'Service uses providedIn: root'}
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-profile',
  template: '<p>User: {{user().name}}</p>',
})
export class UserProfile {
  private userService = inject(UserClient); // Works: providedIn: 'root'
  user = this.userService.getUser();
}
```

#### 依存パスでデバッグする {#debugging-with-the-dependency-path}

エラーメッセージ内の依存パスは、失敗につながった注入の連鎖を示します。

```
NullInjectorError: No provider for LoggerStore!
  Dependency path: App -> DataStore -> ApiClient -> LoggerStore
```

このパスから次のことがわかります。

1. `App`が`DataStore`を注入しました
2. `DataStore`が`ApiClient`を注入しました
3. `ApiClient`が`LoggerStore`を注入しようとしました
4. `LoggerStore`のプロバイダーが見つかりませんでした

連鎖の末尾（`LoggerStore`）から調査を開始し、適切に構成されていることを確認します。

#### オプション注入でプロバイダーの利用可否を確認する {#checking-provider-availability-with-optional-injection}

エラーをスローせずにプロバイダーが存在するかを確認するには、オプション注入を使用します。

```angular-ts
import {Component, inject} from '@angular/core';
import {UserClient} from './user-client';

@Component({
  selector: 'app-debug',
  template: '<p>Service available: {{serviceAvailable}}</p>',
})
export class DebugView {
  private userService = inject(UserClient, {optional: true});
  serviceAvailable = this.userService !== null;
}
```

オプション注入はプロバイダーが見つからない場合に`null`を返すため、不在を穏やかに処理できます。

### NG0203: inject() must be called from an injection context {#ng0203-inject-must-be-called-from-an-injection-context}

**エラーコード:** NG0203

このエラーは、有効な注入コンテキストの外で`inject()`を呼び出した場合に発生します。Angularでは、`inject()`はクラスの構築中またはファクトリの実行中に同期的に呼び出される必要があります。

```
NG0203: inject() must be called from an injection context such as a
constructor, a factory function, a field initializer, or a function
used with `runInInjectionContext`.
```

#### 有効な注入コンテキスト {#valid-injection-contexts}

Angularは次の場所で`inject()`を許可します。

1. **クラスフィールド初期化子**

   ```angular-ts
   import {Component, inject} from '@angular/core';
   import {UserClient} from './user-client';

   @Component({
     selector: 'app-profile',
     template: '<p>User: {{user().name}}</p>',
   })
   export class UserProfile {
     private userService = inject(UserClient); // Valid
     user = this.userService.getUser();
   }
   ```

2. **クラスコンストラクター**

   ```angular-ts
   import {Component, inject} from '@angular/core';
   import {UserClient} from './user-client';

   @Component({
     selector: 'app-profile',
     template: '<p>User: {{user().name}}</p>',
   })
   export class UserProfile {
     private userService: UserClient;

     constructor() {
       this.userService = inject(UserClient); // Valid
     }

     user = this.userService.getUser();
   }
   ```

3. **プロバイダーファクトリ関数**

   ```ts
   import {inject, InjectionToken} from '@angular/core';
   import {UserClient} from './user-client';

   export const GREETING = new InjectionToken<string>('greeting', {
     factory() {
       const userService = inject(UserClient); // Valid
       const user = userService.getUser();
       return `Hello, ${user.name}`;
     },
   });
   ```

4. **runInInjectionContext()の内側**

   ```angular-ts
   import {Component, inject, Injector} from '@angular/core';
   import {UserClient} from './user-client';

   @Component({
     selector: 'app-profile',
     template: '<button (click)="loadUser()">Load User</button>',
   })
   export class UserProfile {
     private injector = inject(Injector);

     loadUser() {
       this.injector.runInInjectionContext(() => {
         const userService = inject(UserClient); // Valid
         console.log(userService.getUser());
       });
     }
   }
   ```

`inject()`が機能するその他の注入コンテキストには、次のものも含まれます。

- [provideAppInitializer](api/core/provideAppInitializer)
- [provideEnvironmentInitializer](api/core/provideEnvironmentInitializer)
- 関数型の[ルートガード](guide/routing/route-guards)
- 関数型の[データリゾルバー](guide/routing/data-resolvers)

#### このエラーが発生する場合 {#when-this-error-occurs}

このエラーは次の場合に発生します。

- ライフサイクルフック（`ngOnInit`、`ngAfterViewInit`など）で`inject()`を呼び出す
- 非同期の関数内で`await`の後に`inject()`を呼び出す
- コールバック（`setTimeout`、`Promise.then()`など）内で`inject()`を呼び出す
- クラス構築フェーズの外で`inject()`を呼び出す

詳細な例と解決策については、「inject()の誤った使用」セクションを参照してください。

#### 解決策と回避策 {#solutions-and-workarounds}

**解決策1:** フィールド初期化子で依存性を取得する（もっとも一般的）

```ts
private userService = inject(UserClient) // Capture at class level
```

**解決策2:** コールバックには`runInInjectionContext()`を使用する

```ts
private injector = inject(Injector)

someCallback() {
  this.injector.runInInjectionContext(() => {
    const service = inject(MyClient)
  })
}
```

**解決策3:** 依存性を注入する代わりにパラメーターとして渡す

```ts
// Instead of injecting inside a callback
setTimeout(() => {
  const service = inject(MyClient) // ERROR
}, 1000)

// Capture first, then use
private service = inject(MyClient)

setTimeout(() => {
  this.service.doSomething() // Use captured reference
}, 1000)
```

### NG0200: Circular dependency detected {#ng0200-circular-dependency-detected}

**エラーコード:** NG0200

このエラーは、2つ以上のサービスが互いに依存し、Angularが解決できない循環依存を作る場合に発生します。

```
NG0200: Circular dependency in DI detected for AuthClient
  Dependency path: AuthClient -> UserClient -> AuthClient
```

依存パスは循環を示しています。`AuthClient`は`UserClient`に依存し、後者は`AuthClient`に依存し返しています。

#### エラーを理解する {#understanding-the-error}

Angularはコンストラクターを呼び出して依存性を注入することで、サービスインスタンスを作成します。サービスが互いに循環的に依存している場合、Angularはどちらを先に作成すべきか判断できません。

#### 一般的な原因 {#common-causes}

- 直接的な循環依存（Service A → Service B → Service A）
- 間接的な循環依存（Service A → Service B → Service C → Service A）
- サービス依存性も持つモジュールファイル内のインポート循環

#### 解決戦略 {#resolution-strategies}

詳細な例と解決策については、「循環依存」セクションを参照してください。

1. **再構成** - 共有ロジックを第3のサービスに抽出します（推奨）
2. **イベントを使用** - 直接の依存をイベントベースの通信に置き換えます
3. **遅延注入** - `Injector.get()`を使用して一方の依存性を遅延させます（最後の手段）

サービスの循環依存に`forwardRef()`を使用しないでください。これはコンポーネント構成内の循環インポートだけを解決します。

### その他のDIエラーコード {#other-di-error-codes}

これらのエラーの詳細な説明と解決策については、[Angularエラーリファレンス](errors)を参照してください。

| エラーコード            | 説明                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------ |
| [NG0204](errors/NG0204) | すべてのパラメーターを解決できません - `@Injectable()`デコレーターがありません            |
| [NG0205](errors/NG0205) | インジェクターはすでに破棄されています - コンポーネント破棄後にサービスへアクセスしています |
| [NG0207](errors/NG0207) | EnvironmentProvidersが誤ったコンテキストにあります - コンポーネントプロバイダーで`provideHttpClient()`を使用しています |

## 次のステップ {#next-steps}

DIエラーに遭遇したら、次のことを意識してください。

1. エラーメッセージと依存パスを注意深く読む
2. 基本構成（デコレーター、`providedIn`、インポート）を確認する
3. 注入コンテキストとタイミングを確認する
4. DevToolsとログ出力を使用して調査する
5. 問題を単純化して切り分ける

依存性の注入に関する特定のトピックをより深く理解するには、次を確認してください。

- [依存性の注入を理解する](guide/di) - DIの中心概念とパターン
- [階層型依存性の注入](guide/di/hierarchical-dependency-injection) - インジェクター階層の仕組み
- [依存性の注入によるテスト](guide/testing) - TestBedの使用と依存性のモック化
