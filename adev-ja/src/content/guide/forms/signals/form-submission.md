# フォーム送信

ユーザーがフォームを送信するとき、アプリケーションでは通常、バリデーションエラーの表示、重複送信の防止、サーバーへのデータ送信など、複数の関心事を一度に扱う必要があります。これらをそれぞれ手動で処理するのは面倒で、エラーも起こりがちです。

シグナルフォームは、フォーム送信のライフサイクル管理に役立つ `submit()` 関数を提供します。このガイドでは、その使い方を説明します。

## `submit()` は何をするのか {#what-does-submit-do}

`submit()` 関数は、特定の順序で処理を実行します。

1. **インタラクティブなフィールドを touched としてマークする** — touchedになった後にだけエラーを表示するフィールドは、ここでバリデーションエラーを表示します。非表示、無効、読み取り専用のフィールドはスキップされます。
1. **バリデーションを確認する** — いずれかのバリデーションルールが失敗している場合、送信は停止し、`action` 関数は実行されません。
1. **action を実行する** — `action` 関数がフォームの現在値で実行されます。実行中は `submitting()` が `true` を返します。
1. **結果を処理する** — actionがエラーを返す場合、それらは対象フィールドにルーティングされます。何も返さない場合、送信は成功として扱われます。

`submit()` 関数は `Promise<boolean>` を返します。actionがエラーなしで完了すると `true` に解決され、バリデーションが失敗するかactionがエラーを返すと `false` に解決されます。

## `FormRoot` でフォーム送信を設定する {#setting-up-form-submission-with-formroot}

`submit()` 関数を使う最も一般的な方法は、`FormRoot` ディレクティブを通じて使うことです。

`FormRoot` ディレクティブは、`<form>` 要素にバインドされると、次の3つを自動的に処理します。

1. **[`novalidate`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/form#novalidate) を設定する** — ブラウザの組み込みバリデーションを無効にし、代わりにシグナルフォームがバリデーションを管理します
1. **デフォルト動作を防ぐ** — フォーム送信時にブラウザがナビゲーションするのを止めます
1. **`submit()` を呼び出す** — ユーザーがフォームを送信したときに送信フローをトリガーします

NOTE: `FormRoot` ディレクティブは、`form` 要素に `novalidate` 属性を自動的に設定します。`FormRoot` を使う場合、手動で追加する必要はありません。

`FormRoot` は送信イベントを処理しますが、フォームデータで _何をするか_ は別途伝える必要があります。そのためには3つが必要です。

1. フォームを `FormRoot` ディレクティブにバインドする
1. `form()` 関数に `submission` オプションを渡す
1. 送信されたデータを管理する `action` 関数を `submission` オプション内に定義する

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, FormRoot, required} from '@angular/forms/signals';

@Component({
  selector: 'app-contact',
  imports: [FormField, FormRoot],
  template: `
    <form [formRoot]="contactForm">
      <label>
        Name
        <input [formField]="contactForm.name" />
      </label>

      <label>
        Email
        <input type="email" [formField]="contactForm.email" />
      </label>

      <button type="submit">Send</button>
    </form>
  `,
})
export class Contact {
  contactModel = signal({
    name: '',
    email: '',
  });

  contactForm = form(
    this.contactModel,
    (schemaPath) => {
      required(schemaPath.name);
      required(schemaPath.email);
    },
    {
      submission: {
        action: async (field) => {
          const result = await saveContact(field().value());
          if (result.ok) return;

          return {kind: 'serverError', message: 'Failed to submit form'};
        },
      },
    },
  );
}
```

`action` 関数は、どのバリデーションルールも失敗していない場合にのみ実行されます。デフォルトでは、保留中の非同期バリデーターは送信をブロックしません（詳細は[バリデーションゲートをignoreValidatorsで制御する](#controlling-validation-gating-with-ignorevalidators)を参照してください）。actionはフィールドツリーと、`root` および `submitted` のフィールドツリーを含む `detail` オブジェクトを受け取ります。これはサブフォームを送信する場合に便利です。

バリデーションが通過した後でも、ネットワークエラーや重複エントリなどのシナリオにより、action自体が失敗することがあります。そのような場合は、エラーを返すことで失敗を表示できます。一方、成功を示すには、`null` や `undefined` を返すか、空の `return` を呼び出すだけで十分です。

## `submitting()` で送信状態を表示する {#showing-submission-state-with-submitting}

フォームが送信処理中かどうかを追跡する必要がある場合、シグナルフォームは、`action` 関数の実行中に `true` を返す `submitting()` シグナルを提供します。これを使ってローディングインジケーターを表示したり、送信ボタンを無効にして重複送信を防いだりします。

```angular-html
<button type="submit" [disabled]="contactForm().submitting()">
  @if (contactForm().submitting()) {
    Sending...
  } @else {
    Send
  }
</button>
```

`action` 関数が成功するかエラーを返すと、`submitting()` シグナルは自動的に `false` に戻ります。

## 送信エラーを管理する {#managing-submission-errors}

### サーバーエラー {#server-errors}

`action` 関数がサーバーと通信する場合、サーバーは特定のフィールドに表示する必要があるエラーを返すことがあります。これらのエラーを `action` から返すと、対象フィールドへルーティングできます。

#### 送信されたフィールド上のエラー {#errors-on-the-submitted-field}

デフォルトでは、`action` から返されたエラーは、送信されたフィールド（`submit()` に渡したフィールドツリー）に割り当てられます。

```ts
action: async (field) => {
  const result = await saveContact(field().value());
  if (result.ok) return;

  return {kind: 'serverError', message: 'Failed to submit form'};
};
```

#### 特定のフィールド上のエラー {#errors-on-specific-fields}

特定のフィールドにエラーをルーティングしたい場合は、そのフィールドを指す `fieldTree` プロパティを含めます。

```ts
action: async (field) => {
  const result = await saveContact(field().value());
  if (result.ok) return;

  return {kind: 'taken', message: result.message, fieldTree: field.email};
};
```

#### 複数のエラー {#multiple-errors}

複数のフィールドでエラーを報告したい場合は、配列を返します。

```ts
action: async (field) => {
  const result = await registerUser(field().value());
  if (result.ok) return;

  return result.errors.map((err: {field: string; message: string}) => ({
    kind: 'serverError',
    message: err.message,
    fieldTree: field[err.field as keyof typeof field],
  }));
};
```

### 送信エラーの自動クリア {#auto-clearing-submission-errors}

ユーザーがフィールドを編集すると、送信エラーは自動的にクリアされます。`action` がemailフィールド上のエラーを返した場合、そのエラーはユーザーがemail値を変更するとすぐに消えます。

これは、リアクティブに再計算されるバリデーションエラーとは異なります。バリデーションルールは変更のたびに再実行され、同じエラーを生成することがあります。送信エラーはサーバーからの1回限りの結果です。一度クリアされると、フォームが再び送信されない限り再表示されません。

TIP: 送信エラーは、フィールドの `errors()` シグナル内でバリデーションエラーと並んで表示されます。テンプレートでエラーを表示する方法については、[フィールド状態管理ガイド](guide/forms/signals/field-state-management)を参照してください。

## `onInvalid` で無効な送信を処理する {#handling-invalid-submissions-with-oninvalid}

バリデーションが失敗すると、`action` 関数は実行されません。最初のエラーまでスクロールする、トーストを表示する、無効なフィールドにフォーカスするなど、失敗した送信試行に対応する必要がある場合は、`onInvalid` コールバックを使います。

```ts
contactForm = form(
  this.contactModel,
  (schemaPath) => {
    required(schemaPath.name);
    required(schemaPath.email);
  },
  {
    submission: {
      action: async (field) => {
        await saveContact(field().value());
      },
      onInvalid: (field) => {
        const firstError = field().errorSummary()[0];
        firstError?.fieldTree().focusBoundControl();
      },
    },
  },
);
```

`onInvalid` コールバックは、`action` と同じ `(field, detail)` パラメータを受け取ります。すべてのインタラクティブなフィールドがtouchedとしてマークされた後に実行されるため、実行時にはバリデーションエラーがすでにUIに表示されています。

## バリデーションゲートを `ignoreValidators` で制御する {#controlling-validation-gating-with-ignorevalidators}

デフォルトでは、`submit()` は保留中のバリデーターを無視します。失敗しているバリデーターがなければ、一部の非同期バリデーターがまだ進行中でもactionは実行されます。`ignoreValidators` オプションを使うと、この振る舞いを制御できます。

| 値          | 振る舞い                                                                       |
| ----------- | ------------------------------------------------------------------------------ |
| `'pending'` | 失敗したバリデーターがなければ、一部が保留中でも送信する（デフォルト）         |
| `'none'`    | すべてのバリデーターが通過した場合のみ送信する。保留中のバリデーターは送信をブロックする |
| `'all'`     | バリデーション状態に関係なく常に送信する                                       |

```ts
contactForm = form(
  this.contactModel,
  (schemaPath) => {
    required(schemaPath.name);
    required(schemaPath.email);
  },
  {
    submission: {
      action: async (field) => {
        await saveContact(field().value());
      },
      ignoreValidators: 'none',
    },
  },
);
```

ユーザー名の利用可否チェックなど、フォームに非同期バリデーターがあり、送信前にすべてのバリデーションを完了する必要がある場合は `'none'` を使います。バリデーション状態に関係なくデータを永続化したい下書き保存のシナリオでは `'all'` を使います。

## `submit()` による手動送信 {#manual-submission-with-submit}

送信をトリガーする最も一般的な方法は `FormRoot` ディレクティブですが、`submit()` を直接呼び出すこともできます。これは、複数ステップのウィザード、自動保存、フォーム要素の外側からの送信トリガーに便利です。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, required, submit} from '@angular/forms/signals';

@Component({
  selector: 'app-contact',
  imports: [FormField],
  template: `
    <label>
      Name
      <input [formField]="contactForm.name" />
    </label>

    <label>
      Email
      <input type="email" [formField]="contactForm.email" />
    </label>

    <button (click)="onSave()">Save</button>
  `,
})
export class Contact {
  contactModel = signal({
    name: '',
    email: '',
  });

  contactForm = form(this.contactModel, (schemaPath) => {
    required(schemaPath.name);
    required(schemaPath.email);
  });

  async onSave() {
    // When calling `submit()` directly, you pass the action as the second argument
    // instead of configuring it in `FormOptions`.
    const success = await submit(this.contactForm, async (field) => {
      const result = await saveContact(field().value());
      if (result.ok) return;

      return {kind: 'serverError', message: 'Failed to save'};
    });

    if (success) {
      // Handle success — navigate, show confirmation, etc.
    }
  }
}
```

## 副作用を処理する {#handling-side-effects}

`submit()` 関数は `Promise<boolean>` を返します。actionがエラーなしで完了すると `true`、バリデーションが失敗するかactionがエラーを返すと `false` です。これを使って、ナビゲーションや通知のような副作用をトリガーします。

```ts
async onSave() {
  const success = await submit(this.contactForm, async (field) => {
    await saveContact(field().value());
  });

  if (success) {
    await this.router.navigate(['/confirmation']);
  }
}
```

サーバーが生成したIDなど、副作用に必要なデータをactionが生成する場合は、その副作用をaction内で処理します。

```ts
async onSave() {
  await submit(this.contactForm, async (field) => {
    const contact = await createContact(field().value());
    await this.router.navigate(['/confirmation', contact.id]);
  });
}
```

`FormRoot` を使う場合も、`FormRoot` が内部で `submit()` を呼び出すため、副作用は `action` の中に置きます。

```ts
submission: {
  action: async (field) => {
    const result = await saveContact(field().value());
    if (result.ok) {
      await this.router.navigate(['/confirmation']);
      return;
    }

    return {kind: 'serverError', message: 'Failed to submit form'};
  },
}
```

## 同時送信 {#concurrent-submissions}

送信が進行中の場合、同じフォームまたはその親のいずれかに対する後続の `submit()` 呼び出しは、actionを実行せずに即座に `false` を返します。これにより、ユーザーが送信アクションを短時間に複数回トリガーした場合の重複送信と副作用を防ぎます。

## 次のステップ {#next-steps}

このガイドでは、フォームの送信とフォーム送信エラーの処理について説明しました。関連ガイドでは、シグナルフォームの他の側面について探求します。

<docs-pill-row>
  <docs-pill href="guide/forms/signals/validation" title="バリデーション" />
  <docs-pill href="guide/forms/signals/field-state-management" title="フィールド状態管理" />
  <docs-pill href="guide/forms/signals/form-logic" title="フォームロジックの追加" />
</docs-pill-row>
