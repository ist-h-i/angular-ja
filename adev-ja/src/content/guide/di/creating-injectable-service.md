# 注入可能なサービスの作成

サービスとは、アプリケーションが必要とする任意の値、関数、機能を含む広いカテゴリーです。
サービスは通常、焦点が絞られ、明確に定義された目的をもつクラスです。
コンポーネントは、依存性の注入 (DI) で使用できるクラスの一種です。

Angularは、モジュール性と再利用性を高めるために、コンポーネントとサービスを区別します。
コンポーネントのビューに関連する機能を他の種類の処理から分離することで、コンポーネントクラスを簡潔で効率的に保てます。

理想的には、コンポーネントの責務はユーザー体験を可能にすることだけです。
コンポーネントは、ビュー（テンプレートによってレンダリングされるもの）とアプリケーションロジック（多くの場合、何らかのモデルの概念を含むもの）の間を仲介するために、データバインディング用のプロパティとメソッドを提供するべきです。

サーバーからのデータ取得、ユーザー入力の検証、コンソールへのログ記録などのタスクを、コンポーネントからサービスに委任できます。
そのようなタスクを注入可能なサービスクラスで定義すると、その機能を任意のコンポーネントから利用できるようになります。
また、状況に応じて同じ種類のサービスに異なるプロバイダーを構成することで、アプリケーションをより適応しやすくできます。

Angularは、これらの原則を厳密に強制するわけではありません。
Angularは、アプリケーションロジックをサービスに整理し、それらのサービスをDIを通じてコンポーネントで利用できるようにすることを容易にして、これらの原則に従いやすくします。

## サービスの例 {#service-examples}

ブラウザコンソールにログを記録するサービスクラスの例を次に示します。

```ts {header: "logger.service.ts (class)"}
export class Logger {
  log(msg: unknown) {
    console.log(msg);
  }
  error(msg: unknown) {
    console.error(msg);
  }
  warn(msg: unknown) {
    console.warn(msg);
  }
}
```

サービスは他のサービスに依存できます。
たとえば、次の `HeroService` は `Logger` サービスに依存し、さらに `BackendService` を使用してヒーローを取得します。
そのサービスは、サーバーから非同期にヒーローを取得するために、さらに `HttpClient` サービスに依存している場合があります。

```ts {header: "hero.service.ts", highlight="[7,8,12,13]"}
import {inject} from '@angular/core';

export class HeroService {
  private heroes: Hero[] = [];

  private backend = inject(BackendService);
  private logger = inject(Logger);

  async getHeroes() {
    // Fetch
    this.heroes = await this.backend.getAll(Hero);
    // Log
    this.logger.log(`Fetched ${this.heroes.length} heroes.`);
    return this.heroes;
  }
}
```

## CLIを使用して注入可能なサービスを作成する {#creating-an-injectable-service-with-the-cli}

Angular CLIは、新しいサービスを作成するコマンドを提供します。次の例では、既存のアプリケーションに新しいサービスを追加します。

`src/app/heroes` フォルダーに新しい `HeroService` クラスを生成するには、次の手順に従います。

1. 次の [Angular CLI](/tools/cli) コマンドを実行します。

```sh
ng generate service heroes/hero
```

このコマンドは、次のデフォルトの `HeroService` を作成します。

```ts {header: 'heroes/hero.service.ts (CLI-generated)'}
import {Service} from '@angular/core';

@Service()
export class HeroService {}
```

`@Service()` デコレーターは、AngularがDIシステムでこのクラスを使用でき、`HeroService` がアプリケーション全体で利用可能であることを指定します。

ヒーローのモックデータを取得するために、`mock.heroes.ts` からヒーローを返す `getHeroes()` メソッドを追加します。

```ts {header: 'hero.service.ts'}
import {Service} from '@angular/core';
import {HEROES} from './mock-heroes';

@Service()
export class HeroService {
  getHeroes() {
    return HEROES;
  }
}
```

明確さと保守性のために、コンポーネントとサービスは別々のファイルに定義することをおすすめします。

## サービスを注入する {#injecting-services}

サービスをコンポーネントに注入するには、依存関係用のクラスフィールドを宣言し、Angularの [`inject`](/api/core/inject) 関数を使用して初期化します。

次の例では、`HeroList` 内で `HeroService` を指定しています。
`heroService` の型は `HeroService` です。

```ts
import {inject} from '@angular/core';

export class HeroList {
  private heroService = inject(HeroService);
}
```

コンポーネントのコンストラクターを使用して、サービスをコンポーネントに注入できます。

```ts {header: 'hero-list.ts (constructor signature)'}
  constructor(private heroService: HeroService)
```

[`inject`](/api/core/inject) メソッドはクラスと関数の両方で使用できますが、コンストラクターメソッドは当然、クラスコンストラクター内でのみ使用できます。ただし、どちらの場合も、通常はコンポーネントの構築または初期化中に、有効な[注入コンテキスト](guide/di/dependency-injection-context)内でのみ依存関係を注入できます。

## 他のサービスにサービスを注入する {#injecting-services-in-other-services}

サービスが別のサービスに依存する場合は、コンポーネントに注入する場合と同じパターンに従います。
次の例では、`HeroService` がその活動を報告するために `Logger` サービスに依存しています。

```ts {header: 'hero.service.ts, highlight: [[3],[9],[12]]}
import {inject, Service} from '@angular/core';
import {HEROES} from './mock-heroes';
import {Logger} from '../logger.service';

@Service()
export class HeroService {
  private logger = inject(Logger);

  getHeroes() {
    this.logger.log('Getting heroes.');
    return HEROES;
  }
}
```

この例では、`getHeroes()` メソッドがヒーローを取得するときにメッセージをログに記録することで、`Logger` サービスを使用しています。

## 次のステップ {#whats-next}

<docs-pill-row>
  <docs-pill href="guide/di/defining-dependency-providers" title="依存性プロバイダーの構成"/>
  <docs-pill href="guide/di/defining-dependency-providers#automatic-provision-for-non-class-dependencies" title="`InjectionToken`"/>
</docs-pill-row>
