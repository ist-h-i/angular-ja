# フォームモデルの設計

シグナルフォームはモデル駆動のアプローチを使用し、提供されたモデルからフォームの状態と構造を直接導出します。フォーム全体の基盤となるため、よく設計されたフォームモデルから始めることが重要です。このガイドでは、フォームモデルを設計するためのベストプラクティスを探ります。

## フォームモデルとドメインモデル {#form-model-vs-domain-model}

フォームはユーザー入力を収集するために使用されます。アプリケーションには、この入力をビジネスロジックやストレージに最適化された形で表現するためのドメインモデルがあるでしょう。しかしこれは多くの場合、フォーム内でデータをモデル化したい方法とは_異なり_ます。

フォームモデルは、UIに表示される生のユーザー入力を表します。たとえばフォームでは、ドメインモデルでは単一のJavaScript `Date` オブジェクトとして表現している場合でも、予定の日付と時間帯を別々の入力フィールドとしてユーザーに選んでもらうことがあります。

```ts
interface AppointmentFormModel {
  name: string; // Appointment owner's name
  date: Date; // Appointment date (carries only date information, time component is unused)
  time: string; // Selected time as a string
}

interface AppointmentDomainModel {
  name: string; // Appointment owner's name
  time: Date; // Appointment time (carries both date and time information)
}
```

フォームでは、ドメインモデルを単に流用するのではなく、入力体験に合わせて調整されたフォームモデルを使用するべきです。

## フォームモデルのベストプラクティス {#form-model-best-practices}

### 具体的な型を使用する {#use-specific-types}

[TypeScriptの型を使用する](/guide/forms/signals/models#using-typescript-types)で示すように、モデルには常にインターフェースまたは型を定義してください。明示的な型は、より良いIntelliSenseを提供し、コンパイル時にエラーを検出し、フォームにどのデータが含まれるかのドキュメントとしても機能します。

### すべてのフィールドを初期化する {#initialize-all-fields}

モデル内のすべてのフィールドに初期値を提供します。

```ts {prefer, header: 'All fields initialized'}
const taskModel = signal({
  title: '',
  description: '',
  priority: 'medium',
  completed: false,
});
```

```ts {avoid, header: 'Partial initialization'}
const taskModel = signal({
  title: '',
  // Missing description, priority, completed
});
```

初期値がないフィールドはフィールドツリー内に存在しないため、フォーム操作でアクセスできなくなります。

### モデルの焦点を絞る {#keep-models-focused}

各モデルは、単一のフォーム、またはまとまりのある関連データの集合を表すべきです。

```ts {prefer, header: 'Focused on a single purpose'}
const loginModel = signal({
  email: '',
  password: '',
});
```

```ts {avoid, header: 'Mixing unrelated concerns'}
const appModel = signal({
  // Login data
  email: '',
  password: '',
  // User preferences
  theme: 'light',
  language: 'en',
  // Shopping cart
  cartItems: [],
});
```

関心事ごとにモデルを分けると、フォームを理解しやすく、再利用しやすくなります。異なるデータ集合を管理している場合は、複数のフォームを作成してください。

### バリデーション要件を考慮する {#consider-validation-requirements}

バリデーションを念頭に置いてモデルを設計します。一緒にバリデーションするフィールドをグループ化します。

```ts {prefer, header: 'Related fields grouped for comparison'}
// Password fields grouped for comparison
interface PasswordChangeData {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}
```

この構造により、`newPassword` が `confirmPassword` と一致するかを確認するようなクロスフィールドバリデーションがより自然になります。

### データ型をUIコントロールに合わせる {#match-data-types-to-ui-controls}

フォームモデルのプロパティは、UIコントロールが期待するデータ型に合わせるべきです。

たとえば、`size` フィールド（6、12、または24本パック）と `quantity` フィールドをもつ飲み物の注文フォームを考えます。UIでは、サイズにドロップダウン（`<select>`）、数量に数値入力（`<input type="number">`）を使用します。

サイズの選択肢は数値に見えますが、`<select>` 要素は文字列値で動作するため、`size` は文字列としてモデル化するべきです。一方、`<input type="number">` は数値で動作するため、`quantity` は数値としてモデル化できます。

```ts {prefer, header: 'Appropriate data types for the bound UI controls'}
interface BeverageOrderFormModel {
  size: string; // Bound to: <select> (option values: "6", "12", "24")
  quantity: number; // Bound to: <input type="number">
}
```

### `undefined` を避ける {#avoid-undefined}

フォームモデルには `undefined` の値やプロパティを含めてはいけません。シグナルフォームでは、フォームの構造はモデルの構造から導出され、`undefined` は空の値をもつフィールドではなく、_フィールドの不在_を意味します。つまり、オプショナルフィールド（例: `{property?: string}`）も暗黙的に `undefined` を許可するため、避ける必要があります。

フォームモデルで空の値をもつプロパティを表現するには、UIコントロールが「空」を意味すると理解できる値を使用します（例: `<input type="text">` では `""`）。カスタムUIコントロールを設計している場合、`null` は「空」を示す値としてうまく機能することがよくあります。

```ts {prefer, header: 'Appropriate empty values'}
interface UserFormModel {
  name: string; // Bound to <input type="text">
  birthday: Date | null; // Bound to <input type="date">
}

// Initialize our form with empty values.
form(signal({name: '', birthday: null}));
```

### 動的構造をもつモデルを避ける {#avoid-models-with-dynamic-structure}

フォームモデルがその値に基づいて形を変える（オブジェクト上のプロパティが変わる）場合、そのフォームモデルは動的構造をもっています。これは、異なるプロパティをもつオブジェクト型のユニオンや、オブジェクトとプリミティブのユニオンなど、モデル型が異なる形の値を許可する場合に発生します。以降のセクションでは、動的構造をもつモデルが魅力的に見えても、最終的には問題になる一般的なシナリオをいくつか見ていきます。

#### 複雑なオブジェクトの空の値 {#empty-value-for-a-complex-object}

既存のシステム内のデータを編集するのではなく、ユーザーにまったく新しいデータを入力してもらうためにフォームを使うことはよくあります。その良い例がアカウント作成フォームです。次のフォームモデルを使って表現できそうです。

```ts
interface CreateAccountFormModel {
  name: {
    first: string;
    last: string;
  };
  username: string;
}
```

フォームを作成するとき、モデルの初期値を何にするべきかというジレンマに直面します。まだユーザーからの入力がないため、`form<CreateAccountFormModel | null>()` を作成したくなるかもしれません。

```ts {avoid, header: 'Using null as empty value for complex object'}
createAccountForm = form<CreateAccountFormModel | null>(signal(/* what goes here, null? */));
```

しかし、シグナルフォームが_モデル駆動_であることを覚えておくことが重要です。モデルが `null` で、`null` には `name` や `username` プロパティがない場合、フォームにもそれらのサブフィールドはありません。代わりに本当に必要なのは、すべてのリーフフィールドが空の値に設定された `CreateAccountFormModel` のインスタンスです。

```ts {prefer, header: 'Same shape value with empty values for properties'}
createAccountForm = form<CreateAccountFormModel>(
  signal({
    name: {
      first: '',
      last: '',
    },
    username: '',
  }),
);
```

この表現を使用すると、必要なすべてのサブフィールドが存在し、テンプレート内で `[formField]` ディレクティブを使用してバインドできます。

```html
First: <input [formField]="createAccountForm.name.first" /> Last:
<input [formField]="createAccountForm.name.last" /> Username:
<input [formField]="createAccountForm.username" />
```

#### 条件付きで非表示または利用不可になるフィールド {#fields-that-are-conditionally-hidden-or-unavailable}

フォームは常に直線的とは限りません。以前のユーザー入力に基づいて条件付きの経路を作成する必要がよくあります。その一例が、ユーザーに異なる支払いオプションを提示するフォームです。まず、そのようなフォームのUIがどのように見えるかを想像してみましょう。

```html
Name: <input type="text" />

<section>
  <h2>Payment Info</h2>
  <input type="radio" /> Credit Card @if (/* credit card selected */) {
  <section>
    Card Number <input type="text" /> Security Code <input type="text" /> Expiration
    <input type="text" />
  </section>
  }
  <input type="radio" /> Bank Account @if (/* bank account selected */) {
  <section>Account Number <input type="text" /> Routing Number <input type="text" /></section>
  }
</section>
```

これを扱う最善の方法は、_すべての_潜在的な支払い方法のフィールドを含む静的構造のフォームモデルを使用することです。スキーマでは、現在利用できないフィールドを非表示または無効化できます。

```ts {prefer, header: 'Static structure model'}
interface BillPayFormModel {
  name: string;
  method: {
    type: string;
    card: {
      cardNumber: string;
      securityCode: string;
      expiration: string;
    };
    bank: {
      accountNumber: string;
      routingNumber: string;
    };
  };
}

const billPaySchema = schema<BillPayFormModel>((billPay) => {
  // Hide credit card details when user has selected a method other than credit card.
  hidden(billPay.method.card, {when: ({valueOf}) => valueOf(billPay.method.type) !== 'card'});
  // Hide bank account details when user has selected a method other than bank account.
  hidden(billPay.method.bank, {when: ({valueOf}) => valueOf(billPay.method.type) !== 'bank'});
});
```

このモデルを使用すると、`card` オブジェクトと `bank` オブジェクトの両方が常にフォームの状態に存在します。ユーザーが支払い方法を切り替えたとき、更新するのは `type` プロパティだけです。ユーザーがカードフィールドに入力したデータは `card` オブジェクトに安全に保存されたままで、切り替え直したときに再表示できる状態になっています。

対照的に、動的フォームモデルは最初、このユースケースに適しているように見えるかもしれません。結局のところ、ユーザーが「Credit Card」を選択した場合、口座番号とルーティング番号のフィールドは不要です。これを判別可能ユニオンとしてモデル化したくなるかもしれません。

```ts {avoid, header: 'Dynamic structure model'}
interface BillPayFormModel {
  name: string;
  method:
    | {
        type: 'card';
        cardNumber: string;
        securityCode: string;
        expiration: string;
      }
    | {
        type: 'bank';
        accountNumber: string;
        routingNumber: string;
      };
}
```

しかし、次のシナリオで何が起きるかを考えてみてください。

1. ユーザーが名前とクレジットカード情報を入力する
2. 送信しようとした直前に、手数料に気づく。
3. 手数料を避けられるならそのほうがよいと考え、代わりに銀行口座オプションへ切り替える。
4. 銀行の口座情報を入力しようとしたところで、漏えいしたら困ると考え直す。
5. クレジットカードオプションに戻すが、入力したばかりの情報がすべて消えていることに気づく。

これは、動的構造をもつフォームモデルのもう1つの問題、つまりデータ損失を引き起こす可能性を示しています。このようなモデルは、フィールドがいったん非表示になると、その中の情報は二度と必要にならないと仮定しています。クレジットカード情報を銀行の口座情報で置き換えてしまい、クレジットカード情報を取り戻す方法がありません。

#### 例外 {#exceptions}

一般的には静的構造が望ましいものの、動的構造が必要でサポートされる特定のシナリオがあります。

##### 配列 {#arrays}

配列はもっとも一般的な例外です。フォームでは、電話番号のリスト、参加者、注文内の明細項目など、可変個数の項目を収集する必要がよくあります。

```ts
interface SendEmailFormModel {
  subject: string;
  recipientEmails: string[];
}
```

この場合、`recipientEmails` 配列はユーザーがフォームを操作するにつれて増減します。配列の長さは動的ですが、個々の項目の構造は一貫しているべきです（各項目は同じ形をもつべきです）。

##### UIコントロールによってアトミックに扱われるフィールド {#fields-that-are-treated-atomically-by-the-ui-control}

動的構造が許容されるもう1つのケースは、複雑なオブジェクトがUIコントロールによって単一のアトミックな値として扱われる場合です。つまり、そのコントロールがサブフィールドへ個別にバインドしたりアクセスしたりしない場合です。このシナリオでは、コントロールは内部プロパティを変更するのではなく、オブジェクト全体を一度に置き換えて値を更新します。このシナリオではフォーム構造が関係しないため、その構造が動的でも許容されます。

たとえば、`location` フィールドを含むユーザープロフィールフォームを考えます。位置情報は、座標オブジェクトを返す複雑な「位置選択」ウィジェット（おそらく地図や検索候補付きドロップダウン）を使用して選択されます。位置情報がまだ選択されていない場合、またはユーザーが位置情報を共有しないことを選んだ場合、ピッカーは位置情報を `null` として示します。

```ts {prefer, header: 'Dynamic structure is ok when field is treated as atomic'}
interface Location {
  lat: number;
  lng: number;
}

interface UserProfileFormModel {
  username: string;
  // This property has dynamic structure,
  // but that's ok because the location picker treats this field as atomic.
  location: Location | null;
}
```

テンプレートでは、`location` フィールドをカスタムコントロールに直接バインドします。

```html
Username: <input [formField]="userForm.username" /> Location:
<location-picker [formField]="userForm.location"></location-picker>
```

ここでは、`<location-picker>` が `Location` オブジェクト全体（または `null`）を受け取り生成し、`userForm.location.lat` や `userForm.location.lng` にはアクセスしません。したがって、`location` はモデル駆動フォームの原則に違反することなく、動的な形を安全にもてます。

## フォームモデルとドメインモデル間の変換 {#translating-between-form-model-and-domain-model}

フォームモデルとドメインモデルは同じ概念を異なる方法で表すため、これらの異なる表現の間で変換する方法が必要です。システム内の既存データをフォームでユーザーに提示したい場合は、ドメインモデル表現からフォームモデル表現へ変換する必要があります。逆に、ユーザーの変更を保存したい場合は、フォームモデル表現からドメインモデル表現へデータを変換する必要があります。

ドメインモデルとフォームモデルがあり、それらの間で変換する関数を書いたと想像してみましょう。

```ts
interface MyDomainModel { ... }

interface MyFormModel { ... }

// Instance of `MyFormModel` populated with empty input (e.g. `''` for string inputs, etc.)
const EMPTY_MY_FORM_MODEL: MyFormModel = { ... };

function domainModelToFormModel(domainModel: MyDomainModel): MyFormModel { ... }

function formModelToDomainModel(formModel: MyFormModel): MyDomainModel { ... }
```

### ドメインモデルからフォームモデルへ {#domain-model-to-form-model}

システム内の既存のドメインモデルを編集するフォームを作成する場合、通常はそのドメインモデルをフォームコンポーネントへの `input()` として受け取るか、バックエンドから（たとえばリソース経由で）受け取ります。どちらの場合でも、`linkedSignal` は変換を適用する優れた方法を提供します。

ドメインモデルを `input()` として受け取る場合、`linkedSignal` を使用して入力シグナルから書き込み可能なフォームモデルを作成できます。

```ts {prefer, header: 'Use linkedSignal to convert domain model to form model'}
@Component(...)
class MyForm {
  // The domain model to initialize the form with, if not given we start with an empty form.
  readonly domainModel = input<MyDomainModel>();

  private readonly formModel = linkedSignal({
    // Linked signal based on the domain model
    source: this.domainModel,
    // If domain model is defined convert it to a form model, otherwise use an empty form model.
    computation: (domainModel) => domainModel
      ? domainModelToFormModel(domainModel)
      : EMPTY_MY_FORM_MODEL
  });

  protected readonly myForm = form(this.formModel);
}
```

同様に、バックエンドからリソース経由でドメインモデルを受け取る場合、その値に基づいて `linkedSignal` を作成し、`formModel` を作成できます。このシナリオでは、ドメインモデルの取得に時間がかかる場合があるため、データが読み込まれるまでフォームを無効化するべきです。

```ts {prefer, header: 'Disable or hide the form when data is unavailable'}
@Component(...)
class MyForm {
  // Fetch the domain model from the backend.
  readonly domainModelResource: ResourceRef<MyDomainModel | undefined> = httpResource(...);

  private readonly formModel = linkedSignal({
    // Linked signal based on the domain model resource
    source: this.domainModelResource.value,
    // Convert the domain model once it loads, use an empty form model while loading.
    computation: (domainModel) => domainModel
      ? domainModelToFormModel(domainModel)
      : EMPTY_MY_FORM_MODEL
  });

  protected readonly myForm = form(this.formModel, (root) => {
    // Disable the entire form when the resource is loading.
    disabled(root, {when: () => this.domainModelResource.isLoading()});
  });
}
```

上記の例は、ドメインモデルから直接フォームモデルを純粋に導出する方法を示しています。しかし場合によっては、新しいドメインモデル値と、以前のドメインモデル値およびフォームモデル値の間で、より高度な差分処理を行いたいことがあります。これは `linkedSignal` の[以前の状態](/guide/signals/linked-signal#accounting-for-previous-state)に基づいて実装できます。

### フォームモデルからドメインモデルへ {#form-model-to-domain-model}

ユーザーの入力をシステムへ保存できる状態になったら、それをドメインモデル表現へ変換する必要があります。これは通常、ユーザーがフォームを送信するとき、または自動保存フォームでユーザーが編集するたびに継続的に行われます。

送信時に保存するには、`submit` 関数内で変換を処理できます。

```ts {prefer, header: 'Convert form model to domain model on submit'}
@Component(...)
class MyForm {
  private readonly myDataService = inject(MyDataService);

  protected readonly myForm = form<MyFormModel>(...);

  handleSubmit() {
    submit(this.myForm, async () => {
      await this.myDataService.update(formModelToDomainModel(this.myForm.value()));
    });
  };
}
```

あるいは、フォームモデルをサーバーへ直接送信し、サーバー側で
フォームモデルからドメインモデルへ変換できます。

継続的な保存では、`effect` 内でドメインモデルを更新します。

```ts {prefer, header: 'Convert form model to domain model in an effect for auto-saving'}
@Component(...)
class MyForm {
  readonly domainModel = model.required<MyDomainModel>()

  protected readonly myForm = form(...);

  constructor() {
    effect(() => {
      // When the form model changes to a valid value, update the domain model.
      if (this.myForm().valid()) {
        this.domainModel.set(formModelToDomainModel(this.myForm.value()));
      }
    });
  };
}
```

上記の例は、フォームモデルからドメインモデルへの純粋な変換を示しています。しかし、フォームモデルの値だけでなく、フォーム状態全体を考慮することもまったく問題ありません。たとえば、送信量を減らすために、ユーザーが変更した内容に基づく部分更新だけをサーバーへ送信したい場合があります。この場合、変換関数はフォーム状態全体を受け取り、フォームの値とdirty状態に基づいてスパースなドメインモデルを返すように設計できます。

```ts
type Sparse<T> = T extends object ? {
    [P in keyof T]?: Sparse<T[P]>;
} : T;

function formStateToPartialDomainModel(
  formState: FieldState<MyFormModel>
): Sparse<MyDomainModel> { ... }
```
