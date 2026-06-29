# 非同期操作

一部のバリデーションでは、バックエンドAPIやサードパーティサービスなどの外部ソースからのデータが必要です。シグナルフォームは、非同期バリデーションのために2つの関数を提供します。HTTPベースのバリデーションには `validateHttp()`、カスタムリソースベースのバリデーションには `validateAsync()` を使用します。

## 非同期バリデーションを使用するタイミング {#when-to-use-async-validation}

バリデーションロジックに外部データが必要な場合は、非同期バリデーションを使用します。一般的な例には次のものがあります。

- **一意性チェック** - ユーザー名やメールアドレスがすでに存在しないことを検証する
- **データベース検索** - 値をサーバー側データと照合する
- **外部APIバリデーション** - 住所、納税者番号、その他のデータをサードパーティサービスで検証する
- **サーバー側ビジネスルール** - サーバーだけが検証できるバリデーションルールを適用する

クライアントで同期的に実行できるチェックには、非同期バリデーションを使用しないでください。形式のバリデーションや静的ルールには、`pattern()`、`email()`、`validate()` などの同期バリデーションルールを使用します。

## 非同期バリデーションの仕組み {#how-async-validation-works}

非同期バリデーションは、すべての同期バリデーションが成功した後にのみ実行されます。バリデーションの実行中、フィールドの `pending()` シグナルは `true` を返します。バリデーションは特定のフィールドへエラーを向けることができ、フィールド値が変わると保留中のリクエストは自動的にキャンセルされます。

ユーザー名の利用可能性をチェックする例を次に示します。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, validateHttp, FormField} from '@angular/forms/signals';

@Component({
  selector: 'app-registration',
  imports: [FormField],
  template: `
    <form>
      <label>
        Username:
        <input [formField]="registrationForm.username" />
      </label>

      @if (registrationForm.username().pending()) {
        <span class="checking">Checking availability...</span>
      }
      @if (registrationForm.username().invalid()) {
        @for (error of registrationForm.username().errors(); track $index) {
          <span class="error">{{ error.message }}</span>
        }
      }
    </form>
  `,
})
export class Registration {
  registrationModel = signal({username: ''});

  registrationForm = form(this.registrationModel, (schemaPath) => {
    validateHttp(schemaPath.username, {
      request: ({value}) => {
        const username = value();
        return username ? `/api/users/check?username=${username}` : undefined;
      },
      onSuccess: (response: {available: boolean}) => {
        return response.available
          ? null
          : {
              kind: 'usernameTaken',
              message: 'Username is already taken',
            };
      },
      onError: (error) => {
        console.error('Validation request failed:', error);
        return {
          kind: 'serverError',
          message: 'Could not verify username availability',
        };
      },
    });
  });
}
```

バリデーションフローは次のように動作します。

1. ユーザーが値を入力する
2. 同期バリデーションルールが先に実行される
3. 同期バリデーションが失敗した場合、非同期バリデーションは実行されない
4. 同期バリデーションが成功した場合、非同期バリデーションが開始され、`pending()` が `true` になる
5. リクエストが完了し、`pending()` が `false` になる
6. レスポンスに基づいてエラーが更新される

## validateHttp() によるHTTPバリデーション {#http-validation-with-validatehttp}

`validateHttp()` 関数は、もっとも一般的な非同期バリデーションの形を提供します。REST APIや任意のHTTPエンドポイントに対して検証する必要がある場合に使用します。

### request関数 {#request-function}

`request` 関数はURL文字列または `HttpResourceRequest` オブジェクトを返します。バリデーションをスキップするには `undefined` を返します。

```ts
import {Component, signal} from '@angular/core';
import {form, validateHttp, FormField} from '@angular/forms/signals';

@Component({
  selector: 'app-registration',
  imports: [FormField],
  template: `...`,
})
export class Registration {
  registrationModel = signal({username: ''});

  // Cache usernames that passed validation
  private validatedUsernames = new Set<string>();

  registrationForm = form(this.registrationModel, (schemaPath) => {
    validateHttp(schemaPath.username, {
      request: ({value}) => {
        const username = value();
        // Skip HTTP request if already validated
        if (this.validatedUsernames.has(username)) return undefined;

        return `/api/users/check?username=${username}`;
      },
      onSuccess: (response: {available: boolean}, {value}) => {
        if (response.available) {
          // Cache successful validations
          this.validatedUsernames.add(value());
          return null;
        }
        return {
          kind: 'usernameTaken',
          message: 'Username is already taken',
        };
      },
      onError: () => ({
        kind: 'serverError',
        message: 'Could not verify username',
      }),
    });
  });
}
```

POSTリクエストやカスタムヘッダーには、`HttpResourceRequest` オブジェクトを返します。

```ts
request: ({value}) => ({
  url: '/api/validate',
  method: 'POST',
  body: {username: value()},
}) // prettier-ignore
```

### 成功ハンドラーとエラーハンドラー {#success-and-error-handlers}

`onSuccess` 関数はHTTPレスポンスを受け取り、有効な値にはバリデーションエラーまたは `undefined` を返します。

```ts
onSuccess: (response: { valid: boolean; message?: string }) => {
  if (response.valid) return undefined;

  return {
    kind: 'invalid',
    message: response.message || 'Validation failed',
  };
} // prettier-ignore
```

必要に応じて複数のエラーを返します。

```ts
onSuccess: (response: { usernameTaken: boolean; profanity: boolean }) => {
  const errors = [];
  if (response.usernameTaken) {
    errors.push({
      kind: 'usernameTaken',
      message: 'Username taken',
    });
  }
  if (response.profanity) {
    errors.push({
      kind: 'profanity',
      message: 'Username contains inappropriate content',
    });
  }
  return errors.length > 0 ? errors : undefined;
} // prettier-ignore
```

`onError` 関数は、ネットワークエラーやHTTPエラーのようなリクエスト失敗を処理します。

```ts
onError: (error) => {
  console.error('Validation request failed:', error);
  return {
    kind: 'serverError',
    message: 'Could not verify. Please try again later.',
  };
} // prettier-ignore
```

### HTTPオプション {#http-options}

`options` パラメータでHTTPリクエストをカスタマイズします。

```ts
import {HttpHeaders} from '@angular/common/http';

validateHttp(schemaPath.field, {
  request: ({value}) => `/api/validate?value=${value()}`,
  options: {
    headers: new HttpHeaders({
      Authorization: 'Bearer token',
    }),
    timeout: 5000,
  },
  onSuccess: (response: {valid: boolean}) =>
    response.valid
      ? null
      : {
          kind: 'invalid',
          message: 'Invalid value',
        },
  onError: () => ({
    kind: 'requestFailed',
    message: 'Unable to reach server to validate.',
  }),
});
```

TIP: 利用可能なすべてのオプションについては、[httpResource APIドキュメント](api/common/http/httpResource)を参照してください。

## validateAsync() によるカスタム非同期バリデーション {#custom-async-validation-with-validateasync}

ほとんどのアプリケーションでは、非同期バリデーションに `validateHttp()` を使用するべきです。これは最小限の設定でHTTPリクエストを処理し、大半のユースケースをカバーします。

`validateAsync()` は、Angularのリソースプリミティブを直接公開する低レベルAPIです。完全な制御を提供しますが、より多くのコードとAngularのリソースAPIへの理解が必要です。

`validateHttp()` で要件を満たせない場合にのみ、`validateAsync()` を検討してください。例には次のものがあります。

- **非HTTPバリデーション** - WebSocket接続、IndexedDB検索、Web Worker計算
- **カスタムキャッシュ戦略** - 単純なメモ化を超えたアプリケーション固有のキャッシュ
- **複雑な再試行ロジック** - カスタムバックオフ戦略や条件付き再試行
- **リソースへの直接アクセス** - 完全なリソースライフサイクルが必要な場合

### カスタムバリデーションルールを作成する {#creating-a-custom-validation-rule}

`validateAsync()` 関数には、`params`、`factory`、`onSuccess`、`onError` の4つのプロパティが必要です。`params` 関数はリソース用のパラメータを返し、`factory` はリソースを作成します。

```ts
import {Component, inject, signal, resource, Signal} from '@angular/core';
import {form, validateAsync, FormField} from '@angular/forms/signals';
import {UsernameValidator} from './username-validator';

@Component({
  selector: 'app-registration',
  imports: [FormField],
  template: `...`,
})
export class Registration {
  registrationModel = signal({username: ''});

  private usernameValidator = inject(UsernameValidator);
  private cache = new Map<string, {available: boolean}>();

  // Custom resource factory with caching
  createUsernameResource = (usernameSignal: Signal<string | undefined>) => {
    return resource({
      params: () => usernameSignal(),
      loader: async ({params: username}) => {
        if (!username) return undefined;

        // Check cache first
        const cached = this.cache.get(username);
        if (cached !== undefined) return cached;

        // Use injected service for validation
        const result = await this.usernameValidator.checkAvailability(username);

        // Cache result
        this.cache.set(username, result);
        return result;
      },
    });
  };

  registrationForm = form(this.registrationModel, (schemaPath) => {
    validateAsync(schemaPath.username, {
      params: ({value}) => {
        const username = value();
        return username.length >= 3 ? username : undefined!;
      },
      factory: this.createUsernameResource,
      onSuccess: (result) => {
        return result?.available
          ? null
          : {
              kind: 'usernameTaken',
              message: 'Username taken',
            };
      },
      onError: (error) => {
        console.error('Validation failed:', error);
        return {
          kind: 'serverError',
          message: 'Could not verify username',
        };
      },
    });
  });
}
```

`params` 関数は値が変更されるたびに実行されます。バリデーションをスキップするには `undefined` を返します。`factory` 関数はセットアップ中に一度実行され、パラメータをシグナルとして受け取ります。パラメータが変わると、リソースは自動的に更新されます。

### Observableベースのサービスを使用する {#using-observable-based-services}

アプリケーションにObservableを返す既存サービスがある場合は、`@angular/core/rxjs-interop` の `rxResource` を使用します。

```ts
import {Component, inject, signal, Signal} from '@angular/core';
import {rxResource} from '@angular/core/rxjs-interop';
import {form, validateAsync, FormField} from '@angular/forms/signals';
import {UsernameService} from './username-service';

@Component({
  selector: 'app-registration',
  imports: [FormField],
  template: `...`,
})
export class Registration {
  registrationModel = signal({username: ''});

  private usernameService = inject(UsernameService);

  private createUsernameResource = (usernameSignal: Signal<string | undefined>) => {
    return rxResource({
      params: () => usernameSignal(),
      stream: ({params: username}) => this.usernameService.checkUsername(username),
    });
  };

  registrationForm = form(this.registrationModel, (schemaPath) => {
    validateAsync(schemaPath.username, {
      params: ({value}) => value(),
      factory: this.createUsernameResource,
      onSuccess: (result) =>
        result?.available ? null : {kind: 'usernameTaken', message: 'Username taken'},
      onError: () => ({
        kind: 'serverError',
        message: 'Could not verify username',
      }),
    });
  });
}
```

`rxResource` 関数はObservableと直接連携し、フィールド値が変わったときのサブスクリプションのクリーンアップを自動的に処理します。

## デバウンス {#debouncing}

`debounce` ルールは、ユーザーの入力がフォームモデルへコミットされるタイミングを遅らせます。ユーザーが入力を一時停止するまで値を保留するルール、と考えられます。高コストな派生計算、単語の入力途中でエラーをちらつかせるバリデーション、各文字ごとに再適用される検索フィルターなど、下流の挙動がすべてのキーストロークに反応するべきでない場合に便利です。

フォームフィールドのUI変更がフォームモデルに到達するタイミングを遅らせるには、スキーマ内に `debounce` ルールを追加します。もっとも単純な形では、`debounce(path, ms)` は各UI変更を指定したミリ秒数だけ保持してからモデルに書き込みます。その時間枠内に新しい変更があると、タイマーはリセットされます。

次の例では、登録フォームでユーザーが入力を一時停止するまでユーザー名の利用可能性チェックを遅らせるため、ユーザー名フィールドに `debounce` と `validateHttp` を適用しています。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, debounce, validateHttp, FormField} from '@angular/forms/signals';

@Component({
  selector: 'app-registration',
  imports: [FormField],
  template: `
    <label>
      Username:
      <input [formField]="registrationForm.username" />
    </label>

    @if (registrationForm.username().pending()) {
      <span class="checking">Checking availability...</span>
    }
  `,
})
export class Registration {
  registrationModel = signal({username: ''});

  registrationForm = form(this.registrationModel, (schemaPath) => {
    // Hold UI updates for 300 ms before writing to the model
    debounce(schemaPath.username, 300);

    // Runs against the debounced model value, not every keystroke
    validateHttp(schemaPath.username, {
      request: ({value}) => {
        const username = value();
        // Skip the request for blank values
        return username ? `/api/users/check?username=${username}` : undefined;
      },
      onSuccess: (response: {available: boolean}) =>
        response.available ? null : {kind: 'usernameTaken', message: 'Username is already taken'},
      onError: () => ({
        kind: 'serverError',
        message: 'Could not verify username availability',
      }),
    });
  });
}
```

300ミリ秒のデバウンスでは、設定された時間より長くユーザーが入力を一時停止した後にのみ、モデルが更新され、バリデーションが実行されます。たとえば、"signal forms" を素早く入力すると、12回ではなく1回のバリデーションリクエストだけが発火します。

### touchがモデルをフラッシュする {#touch-flushes-the-model}

デバウンス時間に関係なく、フィールドがtouchedになると、フレームワークはフィールドの `controlValue()` を即座にモデルへ書き込みます。ネイティブ入力はblurでtouchedになるため、入力を終えてタブ移動したユーザーはデバウンスタイマーの期限切れを待つ必要がありません。カスタムコントロールは、任意のイベントに応じてフィールドをtouchedとしてマークできます。

典型的なケースでは、これはフォーム送信で重要です。ユーザーが送信ボタンをクリックすると、フォーカスされた入力がblurし、そのフィールドがtouchedになって、送信ハンドラーが実行される前に保留中のデバウンスがフラッシュされます。

### blur時にのみコミットする {#commit-only-on-blur}

一部のフィールドは入力途中でまったく更新せず、ユーザーが値の入力を終えた後にのみ更新するべきです。たとえば、変更ごとに再適用される検索フィルターや、高コストな派生状態をトリガーするフォームがある場合、モデルはユーザーが入力を終えるまで待つほうがよいことがよくあります。

このようなシナリオでは、時間の長さではなく `'blur'` を渡し、フィールドがtouchedになるまで、すべての更新を延期します。

```ts
form(this.registrationModel, (schemaPath) => {
  debounce(schemaPath.username, 'blur');
});
```

`'blur'` では、ユーザーが入力している間、モデルは以前の値を保持します。同期および非同期バリデーション、派生シグナル、フィールドを読み取るリアクティブなルールはすべて、フィールドがtouchedになるまで以前の値を参照します。これは一般的に、ユーザーがネイティブ入力をblurしたとき、またはカスタムコントロールが自らtouchを通知したときに発生します。

### カスタムタイミングロジック {#custom-timing-logic}

時間の長さや `'blur'` では表現できないタイミングロジックには、`Debouncer` 関数を渡します。この関数はフィールドコンテキストと [`AbortSignal`](https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal) を受け取り、モデルを更新するべきタイミングで解決される `Promise<void>` を返します。

```ts
import {debounce, type Debouncer} from '@angular/forms/signals';

const shorterWhenLonger: Debouncer<string> = ({value}, abortSignal) => {
  // Shorter queries get a longer delay since the user is likely still typing.
  const ms = value().length < 3 ? 500 : 200;
  return new Promise((resolve) => {
    const timeoutId = setTimeout(resolve, ms);
    // Abort fires when this field is touched or its value changes, so the pending timer is cleared
    abortSignal.addEventListener(
      'abort',
      () => {
        clearTimeout(timeoutId);
        resolve();
      },
      {once: true},
    );
  });
};

const registrationForm = form(registrationModel, (schemaPath) => {
  debounce(schemaPath.username, shorterWhenLonger);
});
```

フィールドがtouchedになるか、デバウンスが解決する前に値が変わると、`abortSignal` が発火します。abort時にpromiseを解決して、デバウンサーが保留中のタイマーを解放するようにします。フレームワークはtouch時に保留中の値をモデルへ書き込み、新しい値が届いたときにはそれを破棄します。完全な `Debouncer` シグネチャについては、[`debounce` APIリファレンス](api/forms/signals/debounce)を参照してください。

### 単一の非同期バリデーターをデバウンスする {#debouncing-a-single-async-validator}

`debounce` ルールは、同期バリデーションから派生シグナル、非同期バリデーションまで、そのフィールドへのすべての反応を保留します。しかし、逆のことをしたい場合もあります。`required` や `email` のような低コストな同期バリデーターは即時フィードバックのためにすぐ実行し、高コストな非同期呼び出しだけはユーザーの入力が落ち着くまで待つ、という場合です。`validateHttp()` と `validateAsync()` はどちらも、そのバリデーターだけを調整する独自の [`debounce` オプション](api/forms/signals/validateAsync)を受け入れます。

```ts
form(this.registrationModel, (schemaPath) => {
  validateHttp(schemaPath.username, {
    // Throttles only this HTTP call
    debounce: 300,
    request: ({value}) => {
      const username = value();
      // Skip the request for blank values
      return username ? `/api/users/check?username=${username}` : undefined;
    },
    onSuccess: (response: {available: boolean}) =>
      response.available ? null : {kind: 'usernameTaken', message: 'Username is already taken'},
    onError: () => ({
      kind: 'serverError',
      message: 'Could not verify username availability',
    }),
  });
});
```

モデルは引き続きキーストロークごとに更新され、そのフィールドに付けられた他のルールも即座に反応します。HTTPリクエストだけがデバウンスされます。各変更は300ミリ秒の静けさを待ってから発火するため、ユーザーが入力を一時停止したときにだけリクエストが送信されます。

スコープに基づいて2つのレイヤーを選択します。

| オプション                                                    | 使用するタイミング                                                                                                                        |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `debounce()` ルール                                           | 同期バリデーション、派生状態、送信のすべてがフィールドのコミットまで待つべき場合。フィールド全体が入力途中に反応するべきではない場合。 |
| `validateHttp({ debounce })` または `validateAsync({ debounce })` | 低コストな同期バリデーターは即時フィードバックを提供し、高コストな非同期呼び出しだけがユーザーの一時停止を待つべき場合。                 |

どちらのオプションもミリ秒単位の時間を受け入れます。カスタムタイミングのコールバックは異なります。フォームレベルのルールは `Debouncer` を受け取り、バリデーターレベルのオプションは `@angular/core` の `DebounceTimer` を受け取ります。2つのシグネチャは互換性がありません。

## factoryによる非同期バリデーションでのリソース合成 {#composing-resources-in-async-validation-with-a-factory}

組み込みの [`debounce` オプション](api/forms/signals/validateAsync)はスロットリングをカバーしますが、`validateAsync()` はより深い合成ポイントである `factory` 関数を公開します。factoryはパラメータをシグナルとして受け取り、リソースを返します。この2点の間で、必要なものを自由に合成できます。

もっとも単純な形では、factoryは単一のリソースをラップします。ユーザー名の利用可能性チェックはコンポーネントクラスのメソッドとして置き、参照によって `validateAsync` に接続できます。

```ts
export class Registration {
  registrationModel = signal({username: ''});
  private usernameValidator = inject(UsernameValidator);

  // Factory function
  checkUsernameAvailable = (username: Signal<string | undefined>) =>
    resource({
      params: () => username(),
      loader: async ({params: name}) => this.usernameValidator.checkAvailability(name),
    });

  registrationForm = form(this.registrationModel, (schemaPath) => {
    validateAsync(schemaPath.username, {
      params: ({value}) => {
        const username = value();
        // Skip validation for short usernames
        return username.length >= 3 ? username : undefined!;
      },
      debounce: 300,
      // Reference to the factory defined above
      factory: this.checkUsernameAvailable,
      onSuccess: (result) =>
        result?.available ? null : {kind: 'usernameTaken', message: 'Username taken'},
      onError: () => ({kind: 'serverError', message: 'Could not verify'}),
    });
  });
}
```

`params` コールバックは短いユーザー名に対して `undefined` を返し、バリデーションをスキップすることを示します。`debounce: 300` が適用されると、リソースは各変更に対して動作する前に、ユーザーが300ミリ秒入力を一時停止するまで待ちます。その後、有効なユーザー名に対してローダーを実行し、デバウンスされた値が `undefined` に落ち着くとアイドル状態のままになります。

### デバウンスと追加ロジックを組み合わせる {#combining-debounce-with-additional-logic}

単純な時間指定デバウンスを超えるロジックが必要な場合は、カスタムfactoryを使用してデバウンスとそのロジックを組み合わせます。一般的なケースは、検証済みレスポンスのキャッシュです。たとえば、サーバーが一度ユーザー名を確認したら、同じ値に戻る後続のキーストロークで再度問い合わせる必要はありません。

```ts
export class Registration {
  registrationModel = signal({username: ''});
  private usernameValidator = inject(UsernameValidator);

  registrationForm = form(this.registrationModel, (schemaPath) => {
    validateAsync(schemaPath.username, {
      params: ({value}) => {
        const username = value();
        return username.length >= 3 ? username : undefined;
      },
      factory: (username) => {
        // Core primitive: settles 300 ms after the source stops changing
        const debouncedUsername = debounced(username, 300);
        // Cache lives in the factory's closure and persists for the field's lifetime
        const cache = new Map<string, {available: boolean}>();
        return resource({
          // Read from the debounced signal, not the raw one
          params: () => debouncedUsername.value(),
          loader: async ({params: name}) => {
            const cached = cache.get(name);
            if (cached) return cached;

            const result = await this.usernameValidator.checkAvailability(name);
            cache.set(name, result);
            return result;
          },
        });
      },
      onSuccess: (result) =>
        result?.available ? null : {kind: 'usernameTaken', message: 'Username taken'},
      onError: () => ({
        kind: 'serverError',
        message: 'Could not verify username',
      }),
    });
  });
}
```

`cache` はfactoryのクロージャ内に存在するため、フィールドが存続する間は保持されます。ユーザーがサーバーでチェック済みのユーザー名を入力すると、ローダーは新しいネットワークリクエストを行う代わりにキャッシュから読み取ります。

## pending状態を理解する {#understanding-pending-state}

非同期バリデーションが実行されると、フィールドの `pending()` シグナルは `true` を返します。この間は次のようになります。

- `valid()` は `false` を返します
- `invalid()` は `false` を返します
- `errors()` は空の配列を返します
- `submit()` はバリデーションの完了を待ちます

フィードバックを提供するために、テンプレートでpending状態を表示します。

```angular-html
<input [formField]="loginForm.username" />

@if (loginForm.username().pending()) {
  <span class="loading">Checking availability...</span>
}

@if (loginForm.username().touched() && loginForm.username().invalid()) {
  @for (error of loginForm.username().errors(); track $index) {
    <span class="error">{{ error.message }}</span>
  }
}
```

バリデーションがpending中はフォーム送信を無効化します。

```angular-html
<button type="submit" [disabled]="loginForm().pending()">
  @if (loginForm().pending()) {
    Validating...
  } @else {
    Submit
  }
</button>
```

TIP: `pending()`、`valid()`、`invalid()` シグナルを使うその他のパターンについては、[フィールド状態管理ガイド](guide/forms/signals/field-state-management)を参照してください。

### バリデーションの実行順序 {#validation-execution-order}

非同期バリデーションは、同期バリデーションが成功した後にのみ実行されます。これにより、無効な入力に対する不要なサーバーリクエストを防ぎます。

```ts
import {form, required, minLength, validateHttp} from '@angular/forms/signals';

form(model, (schemaPath) => {
  // 1. These synchronous validation rules run first
  required(schemaPath.username);
  minLength(schemaPath.username, 3);

  // 2. This async validation rule only runs if synchronous validation passes
  validateHttp(schemaPath.username, {
    request: ({value}) => `/api/check?username=${value()}`,
    onSuccess: (result: {valid: boolean}) =>
      result.valid
        ? null
        : {
            kind: 'usernameTaken',
            message: 'Username taken',
          },
    onError: () => ({
      kind: 'serverError',
      message: 'Validation failed',
    }),
  });
});
```

この実行順序は、サーバー負荷を減らし、形式エラーを即座に検出することでパフォーマンスを向上させます。

### リクエストのキャンセル {#request-cancellation}

フィールド値が変わると、シグナルフォームはそのフィールドに対する保留中の非同期バリデーションリクエストを自動的にキャンセルします。これにより競合状態を防ぎ、バリデーションが常に現在の値を反映することを保証します。キャンセルロジックを自分で実装する必要はありません。

## ベストプラクティス {#best-practices}

### 同期バリデーションと組み合わせる {#combine-with-synchronous-validation}

非同期リクエストを行う前に、必ず形式を検証してください。これにより、エラーを即座に検出し、不要なサーバーリクエストを防ぎます。

```ts
import {form, required, email, validateHttp} from '@angular/forms/signals';

form(model, (schemaPath) => {
  // Validate format first
  required(schemaPath.email);
  email(schemaPath.email);

  // Then check availability
  validateHttp(schemaPath.email, {
    request: ({value}) => `/api/emails/check?email=${value()}`,
    onSuccess: (result: {available: boolean}) =>
      result.available
        ? null
        : {
            kind: 'emailInUse',
            message: 'Email already in use',
          },
    onError: () => ({
      kind: 'serverError',
      message: 'Could not verify email',
    }),
  });
});
```

### 適切な場合はバリデーションをスキップする {#skip-validation-when-appropriate}

バリデーションをスキップするには、`request` 関数から `undefined` を返します。空のフィールドや最小要件を満たさない値の検証を避けるために使用します。

```ts
import {validateHttp} from '@angular/forms/signals';

validateHttp(schemaPath.username, {
  request: ({value}) => {
    const username = value();
    // Skip validation for empty or short usernames
    if (!username || username.length < 3) return undefined;

    return `/api/users/check?username=${username}`;
  },
  onSuccess: (result: {valid: boolean}) =>
    result.valid
      ? null
      : {
          kind: 'usernameTaken',
          message: 'Username taken',
        },
  onError: () => ({
    kind: 'serverError',
    message: 'Validation failed',
  }),
});
```

### エラーを適切に処理する {#handle-errors-gracefully}

明確でユーザーフレンドリーなエラーメッセージを提供します。技術的な詳細はデバッグ用にログに記録し、ユーザーにはシンプルなメッセージを表示します。

```ts
import {validateHttp} from '@angular/forms/signals';

validateHttp(schemaPath.field, {
  request: ({value}) => `/api/validate?field=${value()}`,
  onSuccess: (result: {valid: boolean; message?: string}) => {
    if (result.valid) return null;
    // Use server message when available
    return {
      kind: 'serverError',
      message: result.message || 'Validation failed',
    };
  },
  onError: (error) => {
    // Log for debugging
    console.error('Validation request failed:', error);

    // Show user-friendly message
    return {
      kind: 'serverError',
      message: 'Unable to validate. Please try again later.',
    };
  },
});
```

### 明確なフィードバックを表示する {#show-clear-feedback}

`pending()` シグナルを使用して、バリデーションが実行中であることを表示します。これにより、ユーザーは遅延を理解しやすくなり、体感パフォーマンスも向上します。

```angular-html
@if (field().pending()) {
  <span class="checking">
    <span class="spinner"></span>
    Checking...
  </span>
}
@if (field().valid() && !field().pending()) {
  <span class="success">Available</span>
}
@if (field().invalid()) {
  <span class="error">{{ field().errors()[0]?.message }}</span>
}
```

## 次のステップ {#next-steps}

このガイドでは、`validateHttp()` と `validateAsync()` による非同期バリデーションについて説明しました。関連ガイドでは、シグナルフォームの他の側面を探ります。

<docs-pill-row>
  <docs-pill href="guide/forms/signals/validation" title="バリデーション"/>
  <docs-pill href="guide/forms/signals/field-state-management" title="フィールド状態管理"/>
</docs-pill-row>

詳細なAPIドキュメントについては、次を参照してください。

- [`validateHttp()`](api/forms/signals/validateHttp) - HTTPベースの非同期バリデーション
- [`validateAsync()`](api/forms/signals/validateAsync) - カスタムリソースベースの非同期バリデーション
- [`httpResource()`](api/common/http/httpResource) - AngularのHTTPリソースAPI
- [`resource()`](api/core/resource) - Angularのリソースプリミティブ
