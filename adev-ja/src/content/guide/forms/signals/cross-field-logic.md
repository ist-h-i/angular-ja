# クロスフィールドロジック

**クロスフィールドロジック**は、あるフィールドのルール、バリデーション、または振る舞いが、別のフィールドの値や状態に依存する場合に必要です。

シグナルフォームは、すべてのルール関数に**フィールドコンテキスト**を提供します。フィールドコンテキストは現在のフィールドの値と状態へのアクセスを提供し、`valueOf()`、`stateOf()`、`fieldTreeOf()` を使用してフォーム内の他のフィールドを読み取れるようにします。

このガイドでは、フィールドコンテキストAPIを詳しく説明し、一般的なクロスフィールドパターンを示します。単一フィールドのバリデーションについては、[バリデーションガイド](/guide/forms/signals/validation)を参照してください。

## フィールドコンテキストを理解する {#understanding-the-field-context}

シグナルフォームのすべてのルール関数は、現在のフィールドを説明し、フォームの残りの部分へのアクセスを提供するオブジェクトである**フィールドコンテキスト**パラメータを受け取ります。

現在のフィールドについてアクセスできるプロパティは3つあります。

| プロパティ | 型                   | 説明                                                              |
| ---------- | -------------------- | ----------------------------------------------------------------- |
| `value`    | `Signal<TValue>`     | 現在のフィールドの値を表すシグナル                                |
| `state`    | `FieldState<TValue>` | 現在のフィールドの状態（有効性、エラー、touched、dirtyなど）      |
| `fieldTree` | `FieldTree<TValue>`  | 子フィールドへプログラムからアクセスするための現在のフィールドツリー |

クロスフィールドロジックでは、次の3つのプロパティでフォームの他の部分にアクセスできます。

| プロパティ      | 型                             | 説明                                                                                                               |
| --------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `valueOf()`     | `(path) => PValue`             | もっとも一般的です。比較や計算のために別のフィールドの生の値が必要な場合に使用します。                             |
| `stateOf()`     | `(path) => FieldState<PValue>` | ロジックが別のフィールドの状態（有効か、touchedか、dirtyかなど）に依存する場合に使用します。                       |
| `fieldTreeOf()` | `(path) => FieldTree<PModel>`  | validateTreeで特定の子フィールドにエラーを送るなど、別のフィールドツリーへプログラムからアクセスする場合に使用します。 |

次の例では、`value` と `valueOf()` を使用して、現在のフィールド（終了日）がフォーム内の開始日より後であることを検証します。

```ts
import {Component, signal} from '@angular/core';
import {form, validate} from '@angular/forms/signals';

@Component({
  /* ... */
})
export class EventForm {
  eventModel = signal({
    startDate: new Date('2026-06-01'),
    endDate: new Date('2026-06-05'),
  });

  eventForm = form(this.eventModel, (schemaPath) => {
    validate(schemaPath.endDate, ({value, valueOf}) => {
      if (value() <= valueOf(schemaPath.startDate)) {
        return {
          kind: 'invalidDateRange',
          message: 'End date must be after start date',
        };
      }

      return null;
    });
  });
}
```

NOTE: `fieldContext` パラメータは通常、ルールに必要なものだけを取り出すために分割代入されます。このガイドの残りの例では、このパターンを使用します。

## クロスフィールドバリデーションパターン {#cross-field-validation-patterns}

前のセクションの日付範囲の例では、終了日を開始日と照合して検証しています。このルールは `valueOf(schemaPath.startDate)` を読み取るため、どちらの日付が変更されても自動的に再評価されます。つまり、エラー状態を正しく保つには単一のバリデーターで十分です。

ただし、この単一のバリデーターは終了日フィールドにだけエラーを配置します。範囲が無効なときに両方のフィールドへエラーを表示したい場合は、各フィールドに対応するバリデーションルールを追加します。

```ts
import {Component, signal} from '@angular/core';
import {form, validate} from '@angular/forms/signals';

@Component({
  /* ... */
})
export class EventForm {
  eventModel = signal({
    startDate: new Date('2026-06-01'),
    endDate: new Date('2026-06-05'),
  });

  eventForm = form(this.eventModel, (schemaPath) => {
    validate(schemaPath.startDate, ({value, valueOf}) => {
      if (value() >= valueOf(schemaPath.endDate)) {
        return {
          kind: 'invalidDateRange',
          message: 'Start date must be before end date',
        };
      }
      return null;
    });

    validate(schemaPath.endDate, ({value, valueOf}) => {
      if (value() <= valueOf(schemaPath.startDate)) {
        return {
          kind: 'invalidDateRange',
          message: 'End date must be after start date',
        };
      }
      return null;
    });
  });
}
```

どちらのルールも `valueOf()` を使って他方のフィールドを読み取ります。各ルールはリアクティブなので、どちらの日付が変更されても両方のバリデーションが自動的に再評価されます。

NOTE: ルールが複数のフィールドに関係する場合、エラーをどこに属させるかを決める必要があります。特定のフィールド、複数のフィールド、または親のいずれかです。一般に、ユーザーが問題を修正するためにもっとも向かいやすい場所にエラーを配置します。

### 条件付きの必須項目 {#conditional-requirements}

フォームによっては、特定の条件下でのみ必須になるフィールドがあります。たとえば登録フォームでは、ユーザーがビジネスアカウント種別を選択した場合にのみ会社名を必須にすることがあります。

```ts
import {Component, signal} from '@angular/core';
import {form, required} from '@angular/forms/signals';

@Component({
  /* ... */
})
export class RegistrationForm {
  registrationModel = signal({
    accountType: 'personal' as 'personal' | 'business',
    companyName: '',
  });

  registrationForm = form(this.registrationModel, (schemaPath) => {
    required(schemaPath.companyName, {
      when: ({valueOf}) => valueOf(schemaPath.accountType) === 'business',
      message: 'Company name is required for business accounts',
    });
  });
}
```

`when` オプションは他のルール関数と同じフィールドコンテキストを受け取るため、`valueOf` は同じように機能します。ユーザーが `'personal'` に戻すと、条件が再評価され、必須条件とそのエラーが自動的にクリアされます。

手動の `validate()` チェックではなく `required()` と `when` を使用すると、フィールドに適切な必須メタデータも追加されます。これにより、スクリーンリーダー向けにフィールドを必須としてマークするなどのアクセシビリティ機能が有効になります。

### 別のフィールドの状態に基づくバリデーション {#validating-based-on-another-fields-state}

ここまでの例では、`valueOf()` を使って別のフィールドの値を読み取りました。ロジックが別のフィールドの_状態_、つまり有効か、touchedか、dirtyかに依存することもあります。この場合は `stateOf()` を使用します。

たとえば、パスワード確認フィールドは、ユーザーがパスワードフィールドを操作した後にのみ一致を確認するべきです。ユーザーがまだパスワードに触れていない場合、確認フィールドで不一致を示すのは時期尚早です。

```ts
import {Component, signal} from '@angular/core';
import {form, validate} from '@angular/forms/signals';

@Component({
  /* ... */
})
export class PasswordForm {
  passwordModel = signal({
    password: '',
    confirmPassword: '',
  });

  passwordForm = form(this.passwordModel, (schemaPath) => {
    validate(schemaPath.confirmPassword, ({value, valueOf, stateOf}) => {
      if (!stateOf(schemaPath.password).touched()) {
        return null;
      }
      if (value() !== valueOf(schemaPath.password)) {
        return {
          kind: 'passwordMismatch',
          message: 'Passwords do not match',
        };
      }
      return null;
    });
  });
}
```

`stateOf()` 呼び出しは、他方のフィールドの[フィールド状態](api/forms/signals/FieldState)を返し、`invalid()`、`touched()`、`dirty()` などのシグナルへアクセスできるようにします。これらはシグナルであるため、パスワードフィールドの有効性が変わるたびにルールが再評価されます。

WARNING: 自分のフィールドのバリデーションに依存する状態を読み取らないように注意してください。循環ループが発生します。たとえば、親フィールドが有効かどうかをチェックするバリデーターは、親の有効性が子の有効性（あなたのバリデーターを含む）に依存するため、無限ループを作ります。

## validateTreeを使用する {#using-validatetree}

ここまでの例では、個々のフィールドをチェックするために `validate()` を使用しました。グループ内の複数フィールドに本質的に関係するロジックを検証し、その中の特定の子へエラーを向ける必要がある場合があります。`validateTree` はこの種のシナリオに最適です。

たとえば数独パズルでは、各行に一意の数値を含める必要があります。これはグループレベルのルールです。行全体をチェックし、違反している特定のセルにフラグを立てます。この種のバリデーションは、個々のフィールドに対する `validate` ではきれいに表現できません。各セルが他のすべてのセルについて知る必要があるためです。

```ts
import {Component, signal} from '@angular/core';
import {form, validateTree} from '@angular/forms/signals';

@Component({
  /* ... */
})
export class SudokuRow {
  rowModel = signal({
    cell1: 1,
    cell2: 3,
    cell3: 1,
    cell4: 4,
  });

  rowForm = form(this.rowModel, (schemaPath) => {
    validateTree(schemaPath, ({value, fieldTreeOf}) => {
      const row = value();
      const entries = [
        {val: row.cell1, fieldTree: fieldTreeOf(schemaPath.cell1)},
        {val: row.cell2, fieldTree: fieldTreeOf(schemaPath.cell2)},
        {val: row.cell3, fieldTree: fieldTreeOf(schemaPath.cell3)},
        {val: row.cell4, fieldTree: fieldTreeOf(schemaPath.cell4)},
      ];

      const counts = new Map<number, number>();
      for (const {val} of entries) {
        if (val !== 0) {
          counts.set(val, (counts.get(val) ?? 0) + 1);
        }
      }

      const errors = entries
        .filter(({val}) => val !== 0 && (counts.get(val) ?? 0) > 1)
        .map(({val, fieldTree}) => ({
          kind: 'duplicateInRow',
          message: `${val} already appears in this row`,
          fieldTree,
        }));

      return errors.length > 0 ? errors : null;
    });
  });
}
```

バリデーターは親フィールド（行）で実行され、すべてのセル値を読み取り、重複を数え、繰り返し出現する数値を含む各セルのエラーを返します。各エラーの `fieldTree` プロパティは、どのセルがエラーを表示するべきかをAngularに正確に伝えます。`fieldTree` がなければ、エラーは行自体に適用され、ユーザーが見る必要のある場所には表示されません。

`validateTree` はエラーの配列を返せるため、単一のバリデーターで複数のセルに同時にフラグを立てられます。各エラーにはターゲットを指す `fieldTree` が含まれるため、Angularはエラーを正しいフィールドにルーティングします。

### validateTreeとvalidateを使い分けるタイミング {#when-to-use-validatetree-vs-validate}

エラーが検証対象のフィールドに属する場合は、ルールが他のフィールドを読み取る場合でも、`valueOf()` とともに `validate()` を優先します。次の場合は `validateTree` を選びます。

- バリデーションロジックが単一のフィールドではなく、フィールドのグループに本質的に関係している
- バリデーターが異なる子フィールドをターゲットにしたエラーを返す必要がある

TIP: `validateTree` とその戻り値の型の紹介については、[バリデーションガイド](/guide/forms/signals/validation)を参照してください。

## 次のステップ {#next-steps}

このガイドでは、フィールドコンテキストAPIと一般的なクロスフィールドパターンについて説明しました。関連するシグナルフォームガイドについてさらに学ぶには、次を確認してください。

<docs-pill-row>
  <docs-pill href="guide/forms/signals/validation" title="バリデーション" />
  <docs-pill href="guide/forms/signals/field-state-management" title="フィールド状態管理" />
  <docs-pill href="guide/forms/signals/custom-controls" title="カスタムコントロール" />
</docs-pill-row>
