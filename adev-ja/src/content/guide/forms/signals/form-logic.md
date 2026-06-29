# フォームロジックの追加

シグナルフォームでは、スキーマを使ってフォームにロジックを追加できます。バリデーションロジックは[バリデーションガイド](guide/forms/signals/validation)で扱い、このガイドではスキーマで利用できるその他のルールについて説明します。フィールドを条件付きで無効化したり、他の値に基づいて非表示にしたり、読み取り専用にしたり、ユーザー入力をデバウンスしたり、カスタムコントロール用のメタデータを付与したりできます。

このガイドでは、`disabled()`、`hidden()`、`readonly()`、`debounce()`、`metadata()` のようなルールを使ってフィールドの振る舞いを制御する方法を示します。

## フォームロジックを追加するタイミング {#when-to-add-form-logic}

フィールドの振る舞いが他のフィールド値に依存する場合や、リアクティブに更新する必要がある場合は、ルールを使います。たとえば:

- 注文合計が低すぎる場合に無効になるクーポンコードフィールド
- 配送が必要な場合以外は非表示になる住所フィールド
- API呼び出しを減らすためにデバウンスする検索フィールド

## ルールの仕組み {#how-rules-work}

ルールは、フォーム内の特定のフィールドにリアクティブロジックをバインドします。ほとんどの条件付きルールは、`when` 関数を持つオプションオブジェクトを受け取ります。`when` 関数は、参照しているシグナルが変わるたびに、`computed` と同じように自動的に再計算されます。

```ts
const orderForm = form(this.orderModel, (schemaPath) => {
  disabled(schemaPath.couponCode, {when: ({valueOf}) => valueOf(schemaPath.total) < 50});
  //~~~~~~ ~~~~~~~~~~~~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  //rule     path                   reactive logic function
});
```

リアクティブロジック関数は `FieldContext` オブジェクトを受け取ります。このオブジェクトは、`valueOf()` や `stateOf()` のようなヘルパー関数を通じてフィールドの値と状態へのアクセスを提供します。これらのヘルパーへ直接アクセスするために、分割代入されることがよくあります。

NOTE: スキーマコールバックのパラメータ（これらの例では `schemaPath`）は、フォーム内のすべてのフィールドへのパスを提供する `SchemaPathTree` オブジェクトです。このパラメータには好きな名前を付けられます。

`FieldContext` のプロパティとメソッドの完全な詳細については、[バリデーションガイド](guide/forms/signals/validation)を参照してください。

## `disabled()` でフィールドの更新を防ぐ {#prevent-field-updates-with-disabled}

`disabled()` ルールは、フィールドの無効状態を設定します。

`[formField]` ディレクティブと連携し、フィールドの状態に基づいて `disabled` 属性を自動的にバインドします。そのため、テンプレートに `[disabled]="yourForm.fieldName().disabled()"` を手動で追加する必要はありません。

NOTE: 無効なフィールドはバリデーションをスキップします。つまり、フォームバリデーションチェックに参加しません。フィールドの値は保持されますが、バリデーションされません。バリデーションの振る舞いの詳細については、[バリデーションガイド](guide/forms/signals/validation)を参照してください。

### 常に無効 {#always-disabled}

フィールドを永続的に無効にするには、フィールドパスだけを指定して `disabled()` を呼び出します。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, disabled} from '@angular/forms/signals';

@Component({
  selector: 'app-settings',
  imports: [FormField],
  template: `
    <label>
      System ID (cannot be changed)
      <input [formField]="settingsForm.systemId" />
    </label>
  `,
})
export class Settings {
  settingsModel = signal({
    systemId: 'SYS-12345',
    userName: '',
  });

  settingsForm = form(this.settingsModel, (schemaPath) => {
    disabled(schemaPath.systemId);
  });
}
```

### 条件付きの無効化 {#conditional-disabling}

条件に基づいてフィールドを無効化するには、`true`（無効）または `false`（有効）を返す `when` 関数を指定します。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, disabled} from '@angular/forms/signals';

@Component({
  selector: 'app-order',
  imports: [FormField],
  template: `
    <label>
      Order Total
      <input type="number" [formField]="orderForm.total" />
    </label>

    <label>
      Coupon Code
      <input [formField]="orderForm.couponCode" />
    </label>
  `,
})
export class Order {
  orderModel = signal({
    total: 25,
    couponCode: '',
  });

  orderForm = form(this.orderModel, (schemaPath) => {
    disabled(schemaPath.couponCode, {when: ({valueOf}) => valueOf(schemaPath.total) < 50});
  });
}
```

この例では、注文合計が $50未満の場合、クーポンコードフィールドが無効になります。

### 無効化の理由 {#disabled-reasons}

フィールドを無効化するとき、`true` の代わりに文字列を返すことで、ユーザー向けの説明を提供できます。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, disabled} from '@angular/forms/signals';

@Component({
  selector: 'app-order',
  imports: [FormField],
  template: `
    <label>
      Order Total
      <input type="number" [formField]="orderForm.total" />
    </label>

    <label>
      Coupon Code
      <input [formField]="orderForm.couponCode" />
    </label>

    @if (orderForm.couponCode().disabled()) {
      <div class="info">
        @for (reason of orderForm.couponCode().disabledReasons(); track reason) {
          <p>{{ reason.message }}</p>
        }
      </div>
    }
  `,
})
export class Order {
  orderModel = signal({
    total: 25,
    couponCode: '',
  });

  orderForm = form(this.orderModel, (schemaPath) => {
    disabled(schemaPath.couponCode, {
      when: ({valueOf}) =>
        valueOf(schemaPath.total) < 50 ? 'Order must be $50 or more to use a coupon' : false,
    });
  });
}
```

`when` 関数は次を返します。

- 理由付きでフィールドを無効化する **文字列**
- フィールドを有効化する `false`（任意のfalsy値ではなく、明示的に `false` を使います）

理由には、フィールド状態上の `disabledReasons()` シグナルを通じてアクセスします。各理由には、返した文字列を含む `message` プロパティがあります。

#### 複数の無効化理由 {#multiple-disabled-reasons}

同じフィールドに対して `disabled()` を複数回呼び出すこともでき、返された理由はすべて蓄積されます。

```angular-ts
orderForm = form(this.orderModel, (schemaPath) => {
  disabled(schemaPath.promoCode, {
    when: ({valueOf}) =>
      !valueOf(schemaPath.hasAccount) ? 'You must have an account to use promo codes' : false,
  });
  disabled(schemaPath.promoCode, {
    when: ({valueOf}) => (valueOf(schemaPath.total) < 25 ? 'Order must be at least $25' : false),
  });
});
```

両方の条件がtrueの場合、フィールドには両方の無効化理由が表示されます。このパターンは、分離しておきたい複雑な利用可否ルールに便利です。

## フィールドに `hidden()` 状態を設定する {#configuring-hidden-state-on-fields}

`hidden()` ルールは、フィールドの非表示状態を設定します。ただし、これはプログラム上の状態を設定するだけです。**フィールドをUIに表示するかどうかは自分で制御します**。

IMPORTANT: `disabled` や `readonly` とは異なり、`hidden` 状態にはネイティブDOMプロパティがありません。`[formField]` ディレクティブは要素に `hidden` 属性を適用しません。`hidden()` 状態に基づいてフィールドを条件付きでレンダリングするには、テンプレート内で `@if` またはCSSを使う必要があります。

NOTE: 無効なフィールドと同様に、非表示フィールドもバリデーションをスキップします。詳細は[バリデーションガイド](guide/forms/signals/validation)を参照してください。

### 基本的なフィールド非表示 {#basic-field-hiding}

`true`（非表示）または `false`（表示）を返す `when` 関数とともに `hidden()` を使います。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, hidden} from '@angular/forms/signals';

@Component({
  selector: 'app-profile',
  imports: [FormField],
  template: `
    <label>
      <input type="checkbox" [formField]="profileForm.isPublic" />
      Make profile public
    </label>

    @if (!profileForm.publicUrl().hidden()) {
      <label>
        Public URL
        <input [formField]="profileForm.publicUrl" />
      </label>
    }
  `,
})
export class Profile {
  profileModel = signal({
    isPublic: false,
    publicUrl: '',
  });

  profileForm = form(this.profileModel, (schemaPath) => {
    hidden(schemaPath.publicUrl, {when: ({valueOf}) => !valueOf(schemaPath.isPublic)});
  });
}
```

## `readonly()` で編集不可フィールドを表示する {#display-uneditable-fields-with-readonly}

`readonly()` ルールは、ユーザーがフィールドを更新するのを防ぎます。`[FormField]` ディレクティブはこの状態をHTMLの `readonly` 属性に自動的にバインドします。これにより、ユーザーがフォーカスしてテキストを選択できる状態を保ちながら、編集を防ぎます。

NOTE: 読み取り専用フィールドは[バリデーション](guide/forms/signals/validation)をスキップします。

### 常に読み取り専用 {#always-readonly}

フィールドを永続的に読み取り専用にするには、フィールドパスだけを指定して `readonly()` を呼び出します。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, readonly} from '@angular/forms/signals';

@Component({
  selector: 'app-account',
  imports: [FormField],
  template: `
    <label>
      Username (cannot be changed)
      <input [formField]="accountForm.username" />
    </label>

    <label>
      Email
      <input [formField]="accountForm.email" />
    </label>
  `,
})
export class Account {
  accountModel = signal({
    username: 'johndoe',
    email: 'john@example.com',
  });

  accountForm = form(this.accountModel, (schemaPath) => {
    readonly(schemaPath.username);
  });
}
```

`[FormField]` ディレクティブは、フィールドの状態に基づいて `readonly` 属性を自動的にバインドします。

### 条件付きの読み取り専用 {#conditional-readonly}

条件に基づいてフィールドを読み取り専用にするには、`when` 関数を指定します。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, readonly} from '@angular/forms/signals';

@Component({
  selector: 'app-document',
  imports: [FormField],
  template: `
    <label>
      <input type="checkbox" [formField]="documentForm.isLocked" />
      Lock document
    </label>

    <label>
      Document Title
      <input [formField]="documentForm.title" />
    </label>
  `,
})
export class Document {
  documentModel = signal({
    isLocked: false,
    title: 'Untitled',
  });

  documentForm = form(this.documentModel, (schemaPath) => {
    readonly(schemaPath.title, {when: ({valueOf}) => valueOf(schemaPath.isLocked)});
  });
}
```

`isLocked` がtrueの場合、タイトルフィールドは読み取り専用になります。

## hidden、disabled、readonly を選択する {#choose-between-hidden-disabled-and-readonly}

これら3つの設定関数は、異なる方法でフィールドの利用可否を制御します。

フィールドが次の条件に当てはまる場合は、`hidden()` を選びます。

- UIにまったく表示されるべきでない
- 現在のフォーム状態に関係がない
- 例:「請求先と同じ」がチェックされている場合の配送先住所フィールド

フィールドが次の条件に当てはまる場合は、`disabled()` を選びます。

- 表示されるべきだが編集可能でない
- 利用できない理由を表示する必要がある（無効化理由を使用）
- HTMLフォーム送信から除外されるべき
- 例: フォームが有効になるまで無効な送信ボタン、管理者以外のユーザー向けに無効な承認フィールド

フィールドが次の条件に当てはまる場合は、`readonly()` を選びます。

- 表示されるべきだが編集可能でない
- ユーザーが表示、選択、コピーする必要があるデータを含む
- HTMLフォーム送信に含めるべき
- 例: 注文の確認番号、システム生成の参照コード

3つはいずれも、有効な間はバリデーションをスキップし、ユーザーによる編集を防ぎます。主な違いは次のとおりです。

| 機能                             | `hidden()` | `disabled()` | `readonly()` |
| -------------------------------- | ---------- | ------------ | ------------ |
| UIに表示される                   | No         | Yes          | Yes          |
| ユーザーがフォーカス/選択できる  | No         | No           | Yes          |
| HTMLフォーム送信に含まれる       | No         | No           | Yes          |

## `debounce()` で入力操作を遅延させる {#delay-input-operations-with-debounce}

`debounce()` ルールは、フォームモデルの更新を遅延させます。これはパフォーマンス最適化や、素早い入力中の不要な操作を減らすのに役立ちます。

### デバウンスが行うこと {#what-debouncing-does}

デバウンスしない場合、キー入力のたびにフォームモデルが即座に更新されます。これにより、次のものがトリガーされる可能性があります。

- 変更のたびに再計算されるコストの高い算出シグナル
- 文字を入力するたびのバリデーションチェック
- モデル値に結び付いたAPI呼び出しやその他の副作用

デバウンスはこれらの更新を遅延させ、不要な作業を減らします。

### 基本的なデバウンス {#basic-debouncing}

ミリ秒単位の遅延を指定することで、フィールドをデバウンスできます。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, debounce} from '@angular/forms/signals';

@Component({
  selector: 'app-search',
  imports: [FormField],
  template: `
    <label>
      Search
      <input [formField]="searchForm.query" />
    </label>

    <p>Searching for: {{ searchForm.query().value() }}</p>
  `,
})
export class Search {
  searchModel = signal({
    query: '',
  });

  searchForm = form(this.searchModel, (schemaPath) => {
    debounce(schemaPath.query, 300);
  });
}
```

300msのデバウンスでは:

- ユーザーが入力フィールドに入力する
- 入力が止まってから300ms後にのみフォームモデルが更新される
- ユーザーが入力を続ける場合、各キー入力でタイマーがリセットされる
- ユーザーが300ms停止すると、最終値でモデルが更新される

### タイミング保証 {#timing-guarantees}

`debounce()` 関数は、次の仕組みによってユーザーがデータを失わないことを保証します。

- **touched としてマークされたとき:** 値は即座に同期され、保留中のデバウンス遅延は中止されます。これは、フィールドがフォーカスを失う（blur）とき、または明示的にtouchedとしてマークされたときに発生します。
- **フォーム送信時:** すべてのフィールドはバリデーション前にtouchedとしてマークされるため、すべてのデバウンスされた値が即座に同期されます。

つまり、ユーザーはデバウンス遅延が期限切れになるのを待たずに、素早く入力したり、タブで移動したり、フォームを送信したりできます。

### カスタムデバウンスロジック {#custom-debounce-logic}

より高度に制御するには、値をいつ同期するかを制御するデバウンサー関数を指定します。この関数はコントロール値が更新されるたびに呼び出され、即座に同期するための `undefined`、または解決されるまで同期を防ぐPromiseのどちらかを返せます。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, debounce} from '@angular/forms/signals';

@Component({
  selector: 'app-search',
  imports: [FormField],
  template: `
    <label>
      Search
      <input [formField]="searchForm.query" />
    </label>
  `,
})
export class Search {
  searchModel = signal({
    query: '',
  });

  searchForm = form(this.searchModel, (schemaPath) => {
    debounce(schemaPath.query, () => {
      // Return a promise that resolves after 500ms
      return new Promise<void>((resolve) => {
        setTimeout(() => resolve(), 500);
      });
    });
  });
}
```

デバウンサー関数は次を返せます。

- 値を即座に同期するための `undefined`
- 解決されるまで同期を防ぐ `Promise<void>`

カスタムデバウンスロジックのユースケース:

- 単純な遅延を超えるカスタムタイミングロジックを実装する
- 外部イベントと同期を調整する
- アプリケーション状態に基づいて条件付きでデバウンスする

### デバウンスを使うタイミング {#when-to-use-debouncing}

デバウンスは、次のような場合に最も有用です。

- フィールド値に依存するコストの高い算出シグナルがある
- フィールドがAPI呼び出しやその他の副作用をトリガーする
- 素早い入力中のバリデーションオーバーヘッドを減らしたい
- パフォーマンスプロファイリングで、モデル更新が低速化の原因であることが示されている

次のような場合は、デバウンスを使わないでください。

- 良いUXのためにフィールドが即時更新を必要とする（計算機入力など）
- パフォーマンス上の利点がごくわずか
- ユーザーがリアルタイムのフィードバックを期待している

## `metadata()` でフィールドにデータを関連付ける {#associate-data-with-a-field-using-metadata}

メタデータは、リアクティブなデータをフィールドに付与します。バリデーションルールは内部的にこのシステムを使用しており、ヘルプテキスト、設定、算出された表示値のようなアプリケーション固有の情報のために、独自のキーを公開できます。

シグナルフォームは、組み込みバリデーターが自動的に設定する6つの事前定義済みメタデータキーを提供します。

| キー         | 設定元        | 読み取り方法          |
| ------------ | ------------- | --------------------- |
| `REQUIRED`   | `required()`  | `field().required()`  |
| `MIN`        | `min()`       | `field().min()`       |
| `MAX`        | `max()`       | `field().max()`       |
| `MIN_LENGTH` | `minLength()` | `field().minLength()` |
| `MAX_LENGTH` | `maxLength()` | `field().maxLength()` |
| `PATTERN`    | `pattern()`   | `field().pattern()`   |

`[formField]` ディレクティブは、これらのうち5つ（`REQUIRED`、`MIN`、`MAX`、`MIN_LENGTH`、`MAX_LENGTH`）を、ネイティブフォームコントロール上の対応するHTML属性に自動的にバインドします。`PATTERN` は例外です。シグナルフォームはフィールドごとに複数のパターンをサポートしますが、HTMLの `pattern` 属性は単一の正規表現しか受け付けないためです。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, required, min, max} from '@angular/forms/signals';

@Component({
  selector: 'app-age',
  imports: [FormField],
  template: `
    <label>
      Age (between {{ ageForm.age().min?.() }} and {{ ageForm.age().max?.() }})
      <input type="number" [formField]="ageForm.age" />
    </label>

    @if (ageForm.age().required()) {
      <span class="required-indicator">*</span>
    }
  `,
})
export class Age {
  ageModel = signal({age: 0});

  ageForm = form(this.ageModel, (schemaPath) => {
    required(schemaPath.age);
    min(schemaPath.age, 18);
    max(schemaPath.age, 120);
  });
}
```

### リアクティブなメタデータ {#reactive-metadata}

バリデーションルールは制約を他のフィールドから導出できるため、公開されるメタデータもリアクティブになります。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, max} from '@angular/forms/signals';

@Component({
  selector: 'app-inventory',
  imports: [FormField],
  template: `
    <label>
      Item
      <select [formField]="inventoryForm.item">
        <option value="widget">Widget</option>
        <option value="gadget">Gadget</option>
      </select>
    </label>

    <label>
      Quantity (max: {{ inventoryForm.quantity().max?.() }})
      <input type="number" [formField]="inventoryForm.quantity" />
    </label>
  `,
})
export class Inventory {
  inventoryModel = signal({
    item: 'widget',
    quantity: 0,
  });

  inventoryForm = form(this.inventoryModel, (schemaPath) => {
    max(schemaPath.quantity, ({valueOf}) => {
      const item = valueOf(schemaPath.item);
      return item === 'widget' ? 100 : 50;
    });
  });
}
```

`max()` バリデーションルールは、選択されたitemに基づいて `MAX` メタデータをリアクティブに設定します。そのため、`field().max()` を読み取るテンプレートやコントロールは、itemが変わるたびに更新されます。

カスタムキーの定義、リデューサーによるコントリビューションの組み合わせ、ライフサイクルを意識したオブジェクト向けの管理対象メタデータの使用など、さらに詳しい内容については、[フィールドメタデータガイド](guide/forms/signals/field-metadata)を参照してください。

## ルールを組み合わせる {#combining-rules}

同じフィールドに複数のルールを適用できます。また、条件付きロジックを使って、フォーム状態に基づいてルールのグループ全体を適用できます。

### 1つのフィールドに複数のルール {#multiple-rules-on-one-field}

複数のルールを適用して、フィールドの振る舞いのあらゆる側面を設定します。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, disabled, hidden, debounce, metadata} from '@angular/forms/signals';
import {PLACEHOLDER} from './metadata-keys';

@Component({
  selector: 'app-promo',
  imports: [FormField],
  template: `
    @if (!promoForm.promoCode().hidden()) {
      <label>
        Promo Code
        <input [formField]="promoForm.promoCode" />
      </label>
    }
  `,
})
export class Promo {
  promoModel = signal({
    hasAccount: false,
    subscriptionType: 'free' as 'free' | 'premium',
    promoCode: '',
  });

  promoForm = form(this.promoModel, (schemaPath) => {
    disabled(schemaPath.promoCode, {
      when: ({valueOf}) => (!valueOf(schemaPath.hasAccount) ? 'You must have an account' : false),
    });
    hidden(schemaPath.promoCode, {
      when: ({valueOf}) => valueOf(schemaPath.subscriptionType) === 'free',
    });
    debounce(schemaPath.promoCode, 300);
    metadata(schemaPath.promoCode, PLACEHOLDER, () => 'Enter promo code');
  });
}
```

これらのルールは一緒に機能します。

- 非表示が優先される。フィールドが非表示の場合、無効状態は問題にならない
- 無効状態は、読み取り専用状態に関係なく編集を防ぐ
- デバウンスは、他の状態に関係なくモデル更新に影響する
- メタデータは独立しており、常に利用できる

### applyWhen による条件付きロジック {#conditional-logic-with-applywhen}

`applyWhen()` を使うと、ルールのグループ全体を条件付きで適用できます。

```angular-ts
import {Component, signal} from '@angular/core';
import {form, FormField, applyWhen, required, pattern} from '@angular/forms/signals';

@Component({
  selector: 'app-address',
  imports: [FormField],
  template: `
    <label>
      Country
      <select [formField]="addressForm.country">
        <option value="US">United States</option>
        <option value="CA">Canada</option>
      </select>
    </label>

    <label>
      Zip/Postal Code
      <input [formField]="addressForm.zipCode" />
    </label>
  `,
})
export class Address {
  addressModel = signal({
    country: 'US',
    zipCode: '',
  });

  addressForm = form(this.addressModel, (schemaPath) => {
    applyWhen(
      schemaPath,
      ({valueOf}) => valueOf(schemaPath.country) === 'US',
      (schemaPath) => {
        // Only applied when country is US
        required(schemaPath.zipCode);
        pattern(schemaPath.zipCode, /^\d{5}(-\d{4})?$/);
      },
    );
  });
}
```

`applyWhen()` 関数は次を受け取ります。

1. ロジックを適用するパス（多くの場合はルートフォームパス）
2. `true`（適用する）または `false`（適用しない）を返すリアクティブロジック関数
3. 条件付きルールを定義するスキーマ関数

条件付きルールは、条件がtrueの場合にのみ実行されます。これは、ユーザーの選択に基づいてバリデーションルールや振る舞いが変わる複雑なフォームで便利です。

### 再利用可能なスキーマ関数 {#reusable-schema-functions}

共通のルール設定を再利用可能な関数に抽出します。

```ts
import {SchemaPath, debounce, metadata, maxLength} from '@angular/forms/signals';
import {PLACEHOLDER} from './metadata-keys';

function emailFieldConfig(path: SchemaPath<string>) {
  debounce(path, 300);
  metadata(path, PLACEHOLDER, () => 'user@example.com');
  maxLength(path, 255);
}

// Use in multiple forms
const contactForm = form(contactModel, (schemaPath) => {
  emailFieldConfig(schemaPath.email);
  emailFieldConfig(schemaPath.alternateEmail);
});

const registrationForm = form(registrationModel, (schemaPath) => {
  emailFieldConfig(schemaPath.email);
});
```

このパターンは、アプリケーション内の複数のフォームで使う標準的なフィールド設定がある場合に便利です。

## 次のステップ {#next-steps}

シグナルフォームについてさらに学ぶには、次の関連ガイドを確認してください。

- [フィールド状態管理](guide/forms/signals/field-state-management) - これらの関数が作成する状態シグナルをテンプレートやコンポーネントロジックで使う方法を学ぶ
- [バリデーション](guide/forms/signals/validation) - バリデーションルールとエラー処理について学ぶ
- [カスタムコントロール](guide/forms/signals/custom-controls) - カスタムコントロールがメタデータと状態を読み取り、自身を自動的に設定する方法を学ぶ
