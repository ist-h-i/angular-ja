# ドラッグアンドドロップ

## 概要 {#overview}

このページでは、次のようなドラッグアンドドロップのインターフェースをすばやく作成できるドラッグアンドドロップディレクティブについて説明します。

- 自由なドラッグ
- 並べ替え可能なドラッグ可能要素のリストを作成する
- リスト間でドラッグ可能要素を転送する
- ドラッグアニメーション
- 軸または要素に沿ってドラッグ可能要素をロックする
- カスタムドラッグハンドルを追加する
- ドラッグ時にプレビューを追加する
- カスタムドラッグプレースホルダーを追加する

完全なAPIリファレンスについては、[Angular CDKのドラッグアンドドロップAPIリファレンスページ](/api/#angular_cdk_drag-drop)を参照してください。

## 始める前に {#before-you-start}

### CDKのインストール {#cdk-installation}

[Component Dev Kit (CDK)](https://material.angular.dev/cdk/categories)は、コンポーネントを構築するための振る舞いのプリミティブのセットです。ドラッグアンドドロップディレクティブを使用するには、まずnpmから`@angular/cdk`をインストールします。Angular CLIを使ってターミナルから次のように実行できます。

```shell
ng add @angular/cdk
```

### ドラッグアンドドロップのインポート {#importing-drag-and-drop}

ドラッグアンドドロップを使用するには、コンポーネント内でディレクティブから必要なものをインポートします。

```ts
import {Component} from '@angular/core';
import {CdkDrag} from '@angular/cdk/drag-drop';

@Component({
  selector: 'drag-drop-example',
  templateUrl: 'drag-drop-example.html',
  imports: [CdkDrag],
})
export class DragDropExample {}
```

## ドラッグ可能な要素を作成する {#create-draggable-elements}

任意の要素に`cdkDrag`ディレクティブを追加すると、その要素をドラッグ可能にできます。デフォルトでは、すべてのドラッグ可能要素は自由なドラッグをサポートします。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/overview/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/overview/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/overview/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/overview/app/app.css"/>
</docs-code-multifile>

## 並べ替え可能なドラッグ可能要素のリストを作成する {#create-a-list-of-reorderable-draggable-elements}

親要素に`cdkDropList`ディレクティブを追加すると、ドラッグ可能要素を並べ替え可能なコレクションにグループ化できます。これにより、ドラッグ可能要素をドロップできる場所が定義されます。ドロップリストグループ内のドラッグ可能要素は、要素の移動に応じて自動的に並べ替わります。

ドラッグアンドドロップディレクティブは、データモデルを更新しません。データモデルを更新するには、`cdkDropListDropped`イベント（ユーザーがドラッグを完了した時点）をリッスンし、データモデルを手動で更新します。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/sorting/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/sorting/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/sorting/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/sorting/app/app.css"/>
</docs-code-multifile>

`cdkDropList`のインスタンスを参照するために使用できる`CDK_DROP_LIST`インジェクショントークンを使用できます。詳細については、[依存性の注入ガイド](/guide/di)と[ドロップリストのインジェクショントークンAPI](api/cdk/drag-drop/CDK_DROP_LIST)を参照してください。

## リスト間でドラッグ可能要素を転送する {#transfer-draggable-elements-between-lists}

`cdkDropList`ディレクティブは、接続されたドロップリスト間でのドラッグ可能要素の転送をサポートします。1つ以上の`cdkDropList`インスタンスを接続するには、次の2つの方法があります。

- `cdkDropListConnectedTo`プロパティを別のドロップリストに設定する。
- 要素を`cdkDropListGroup`属性を持つ要素でラップする。

`cdkDropListConnectedTo`ディレクティブは、別の`cdkDropList`への直接参照でも、別のドロップコンテナーのIDを参照する方法でも機能します。

```html
<!-- これは有効です -->
<div cdkDropList #listOne="cdkDropList" [cdkDropListConnectedTo]="[listTwo]"></div>
<div cdkDropList #listTwo="cdkDropList" [cdkDropListConnectedTo]="[listOne]"></div>

<!-- これも有効です -->
<div cdkDropList id="list-one" [cdkDropListConnectedTo]="['list-two']"></div>
<div cdkDropList id="list-two" [cdkDropListConnectedTo]="['list-one']"></div>
```

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/connected-sorting/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/connected-sorting/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/connected-sorting/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/connected-sorting/app/app.css"/>
</docs-code-multifile>

接続するドロップリストの数が不明な場合は、`cdkDropListGroup`ディレクティブを使用して接続を自動的に設定します。グループの下に追加された新しい`cdkDropList`は、他のすべてのリストに自動的に接続されます。

```angular-html
<div cdkDropListGroup>
  <!-- ここにあるすべてのリストが接続されます。 -->
  @for (list of lists; track list) {
    <div cdkDropList></div>
  }
</div>
```

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/connected-sorting-group/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/connected-sorting-group/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/connected-sorting-group/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/connected-sorting-group/app/app.css"/>
</docs-code-multifile>

`cdkDropListGroup`のインスタンスを参照するために使用できる`CDK_DROP_LIST_GROUP`インジェクショントークンを使用できます。詳細については、[依存性の注入ガイド](/guide/di)と[ドロップリストグループのインジェクショントークンAPI](api/cdk/drag-drop/CDK_DROP_LIST_GROUP)を参照してください。

### 選択的なドラッグ {#selective-dragging}

デフォルトでは、ユーザーは`cdkDrag`要素をあるコンテナーから別の接続済みコンテナーへ移動できます。コンテナーにドロップできる要素をより細かく制御するには、`cdkDropListEnterPredicate`を使用します。Angularは、ドラッグ可能要素が新しいコンテナーに入るたびにこの述語を呼び出します。述語がtrueまたはfalseのどちらを返すかに応じて、そのアイテムが新しいコンテナーへ入ることが許可されるかどうかが決まります。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/enter-predicate/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/enter-predicate/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/enter-predicate/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/enter-predicate/app/app.css"/>
</docs-code-multifile>

## データを添付する {#attach-data}

`cdkDragData`または`cdkDropListData`をそれぞれ設定することで、`cdkDrag`と`cdkDropList`の両方に任意のデータを関連付けられます。両方のディレクティブから発火されるイベントにバインドでき、それらのイベントにはこのデータが含まれるため、ドラッグやドロップ操作の起点を簡単に識別できます。

```angular-html
@for (list of lists; track list) {
  <div cdkDropList [cdkDropListData]="list" (cdkDropListDropped)="drop($event)">
    @for (item of list; track item) {
      <div cdkDrag [cdkDragData]="item"></div>
    }
  </div>
}
```

## ドラッグのカスタマイズ {#dragging-customizations}

### ドラッグハンドルをカスタマイズする {#customize-drag-handle}

デフォルトでは、ユーザーは`cdkDrag`要素全体をドラッグして移動できます。ユーザーがハンドル要素だけを使ってドラッグできるように制限するには、`cdkDrag`内の要素に`cdkDragHandle`ディレクティブを追加します。`cdkDragHandle`要素はいくつでも設定できます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/custom-handle/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/custom-handle/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/custom-handle/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/custom-handle/app/app.css"/>
</docs-code-multifile>

`cdkDragHandle`のインスタンスを参照するために使用できる`CDK_DRAG_HANDLE`インジェクショントークンを使用できます。詳細については、[依存性の注入ガイド](/guide/di)と[ドラッグハンドルのインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_HANDLE)を参照してください。

### ドラッグプレビューをカスタマイズする {#customize-drag-preview}

`cdkDrag`要素がドラッグされている間、プレビュー要素が表示されます。デフォルトでは、プレビューは元の要素のクローンで、ユーザーのカーソルの近くに配置されます。

プレビューをカスタマイズするには、`*cdkDragPreview`でカスタムテンプレートを指定します。カスタムプレビューでは要素の内容について仮定しないため、ドラッグ元の要素と同じサイズにはなりません。ドラッグプレビューのサイズを要素に合わせるには、`matchSize`入力にtrueを渡します。

クローンされた要素は、ページ上に同じIDを持つ複数の要素が存在することを避けるため、id属性が削除されます。そのため、そのIDを対象にしたCSSは適用されません。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/custom-preview/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/custom-preview/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/custom-preview/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/custom-preview/app/app.css"/>
</docs-code-multifile>

`cdkDragPreview`のインスタンスを参照するために使用できる`CDK_DRAG_PREVIEW`インジェクショントークンを使用できます。詳細については、[依存性の注入ガイド](/guide/di)と[ドラッグプレビューのインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_PREVIEW)を参照してください。

### ドラッグ挿入位置をカスタマイズする {#customize-drag-insertion-point}

デフォルトでは、Angularは配置やオーバーフローの問題を避けるため、`cdkDrag`プレビューをページの`<body>`内に挿入します。プレビューに継承されたスタイルが適用されないため、場合によっては望ましくないことがあります。

Angularがプレビューを挿入する場所は、`cdkDrag`の`cdkDragPreviewContainer`入力で変更できます。指定できる値は次のとおりです。

| 値                            | 説明                                                                                   | 利点                                                                                                                         | 欠点                                                                                                                                                                      |
| :---------------------------- | :------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `global`                      | デフォルト値です。Angularはプレビューを<body>またはもっとも近いシャドウルートに挿入します。 | プレビューは`z-index`や`overflow: hidden`の影響を受けません。また、`:nth-child`セレクターやflexレイアウトにも影響しません。 | 継承されたスタイルは保持されません。                                                                                                                                      |
| `parent`                      | Angularはプレビューを、ドラッグされている要素の親の内側に挿入します。                  | プレビューはドラッグ元の要素と同じスタイルを継承します。                                                                    | プレビューは`overflow: hidden`で切り取られたり、`z-index`によって他の要素の下に配置されたりすることがあります。さらに、`:nth-child`セレクターや一部のflexレイアウトに影響することがあります。 |
| `ElementRef`または`HTMLElement` | Angularはプレビューを指定された要素に挿入します。                                      | プレビューは指定されたコンテナー要素からスタイルを継承します。                                                              | プレビューは`overflow: hidden`で切り取られたり、`z-index`によって他の要素の下に配置されたりすることがあります。さらに、`:nth-child`セレクターや一部のflexレイアウトに影響することがあります。 |

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、値が`global`または`parent`の場合に設定内の`previewContainer`を更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### ドラッグプレースホルダーをカスタマイズする {#customize-drag-placeholder}

`cdkDrag`要素がドラッグされている間、ディレクティブはドロップ時に要素が配置される場所を示すプレースホルダー要素を作成します。デフォルトでは、プレースホルダーはドラッグされている要素のクローンです。`*cdkDragPlaceholder`ディレクティブを使用して、プレースホルダーをカスタムのものに置き換えられます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/custom-placeholder/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/custom-placeholder/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/custom-placeholder/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/custom-placeholder/app/app.css"/>
</docs-code-multifile>

`cdkDragPlaceholder`のインスタンスを参照するために使用できる`CDK_DRAG_PLACEHOLDER`インジェクショントークンを使用できます。詳細については、[依存性の注入ガイド](/guide/di)と[ドラッグプレースホルダーのインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_PLACEHOLDER)を参照してください。

### ドラッグルート要素をカスタマイズする {#customize-drag-root-element}

ドラッグ可能にしたい要素があり、その要素へ直接アクセスできない場合は、`cdkDragRootElement`属性を設定します。

この属性はセレクターを受け取り、一致する要素が見つかるまでDOMをさかのぼって検索します。要素が見つかると、その要素がドラッグ可能になります。これは、ダイアログをドラッグ可能にするようなケースで役立ちます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/root-element/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/root-element/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/root-element/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/root-element/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内の`rootElementSelector`を更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### ドラッグ可能要素のDOM位置を設定する {#set-dom-position-of-a-draggable-element}

デフォルトでは、`cdkDropList`内にない`cdkDrag`要素は、ユーザーが手動でその要素を移動したときだけ通常のDOM位置から移動します。要素の位置を明示的に設定するには、`cdkDragFreeDragPosition`入力を使用します。一般的なユースケースは、ユーザーが別の場所へ移動してから戻ってきた後に、ドラッグ可能要素の位置を復元することです。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/free-drag-position/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/free-drag-position/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/free-drag-position/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/free-drag-position/app/app.css"/>
</docs-code-multifile>

### 要素内に移動を制限する {#restrict-movement-within-an-element}

ユーザーが`cdkDrag`要素を別の要素の外へドラッグできないようにするには、`cdkDragBoundary`属性にCSSセレクターを渡します。この属性はセレクターを受け取り、一致する要素が見つかるまでDOMをさかのぼって検索します。一致する要素が見つかると、その要素がドラッグ可能要素を外へドラッグできない境界になります。`cdkDragBoundary`は、`cdkDrag`が`cdkDropList`内に配置されている場合にも使用できます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/boundary/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/boundary/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/boundary/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/boundary/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内のboundaryElementを更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### 軸に沿って移動を制限する {#restrict-movement-along-an-axis}

デフォルトでは、`cdkDrag`はすべての方向への自由な移動を許可します。ドラッグを特定の軸に制限するには、`cdkDrag`で`cdkDragLockAxis`を"x"または"y"に設定します。`cdkDropList`内の複数のドラッグ可能要素に対してドラッグを制限するには、代わりに`cdkDropList`で`cdkDropListLockAxis`を設定します。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/axis-lock/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/axis-lock/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/axis-lock/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/axis-lock/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内の`lockAxis`を更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### ドラッグを遅延させる {#delay-dragging}

デフォルトでは、ユーザーが`cdkDrag`上でポインターを押し下げると、ドラッグシーケンスが開始されます。この振る舞いは、タッチデバイス上の全画面のドラッグ可能要素のように、ユーザーがページをスクロールしているときに誤ってドラッグイベントを発生させる可能性があるケースでは望ましくないことがあります。

`cdkDragStartDelay`入力を使用して、ドラッグシーケンスを遅延できます。この入力は、指定されたミリ秒数だけユーザーがポインターを押し続けるまで待ってから、要素のドラッグを開始します。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/delay-drag/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/delay-drag/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/delay-drag/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/delay-drag/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内のdragStartDelayを更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### ドラッグを無効にする {#disable-dragging}

特定のドラッグアイテムのドラッグを無効にしたい場合は、`cdkDrag`アイテムの`cdkDragDisabled`入力をtrueまたはfalseに設定します。`cdkDropList`の`cdkDropListDisabled`入力を使用して、リスト全体を無効にできます。`cdkDragHandle`の`cdkDragHandleDisabled`を通じて、特定のハンドルも無効にできます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/disable-drag/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/disable-drag/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/disable-drag/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/disable-drag/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内の`draggingDisabled`を更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

## 並べ替えのカスタマイズ {#sorting-customizations}

### リストの向き {#list-orientation}

デフォルトでは、`cdkDropList`ディレクティブはリストが縦向きであると仮定します。これは`cdkDropListOrientation`プロパティをhorizontalに設定することで変更できます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/horizontal-sorting/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/horizontal-sorting/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/horizontal-sorting/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/horizontal-sorting/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内の`listOrientation`を更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### リストの折り返し {#list-wrapping}

デフォルトでは、`cdkDropList`はCSS transformを使用してドラッグ可能要素を動かし、並べ替えます。これにより並べ替えをアニメーションでき、より良いユーザー体験を提供できます。ただし、ドロップリストが縦方向または横方向の単方向でしか機能しないという欠点もあります。

新しい行に折り返す必要があるソート可能なリストがある場合は、`cdkDropListOrientation`属性を`mixed`に設定できます。これにより、リストは要素をDOM内で移動する別の並べ替え戦略を使用します。ただし、リストは並べ替えアクションをアニメーションできなくなります。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/mixed-sorting/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/mixed-sorting/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/mixed-sorting/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/mixed-sorting/app/app.css"/>
</docs-code-multifile>

### 選択的な並べ替え {#selective-sorting}

デフォルトでは、`cdkDrag`要素は`cdkDropList`内の任意の位置に並べ替えられます。この振る舞いを変更するには、関数を受け取る`cdkDropListSortPredicate`属性を設定します。述語関数は、ドラッグ可能要素がドロップリスト内の新しいインデックスへ移動されようとするたびに呼び出されます。述語がtrueを返す場合、アイテムは新しいインデックスへ移動されます。それ以外の場合は、現在の位置を維持します。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/sort-predicate/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/sort-predicate/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/sort-predicate/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/sort-predicate/app/app.css"/>
</docs-code-multifile>

### 並べ替えを無効にする {#disable-sorting}

ドラッグ可能要素をある`cdkDropList`から別のドロップリストへドラッグできる一方で、ユーザーが元のリスト内でそれらを並べ替えられてはならないケースがあります。このような場合は、`cdkDropListSortingDisabled`属性を追加して、`cdkDropList`内のドラッグ可能要素が並べ替えられないようにします。これにより、ドラッグされた要素が新しい有効な位置へドラッグされない場合、元のリスト内での初期位置が保持されます。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/disable-sorting/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/disable-sorting/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/disable-sorting/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/disable-sorting/app/app.css"/>
</docs-code-multifile>

別の方法として、`CDK_DRAG_CONFIG`インジェクショントークンを変更し、設定内のsortingDisabledを更新できます。詳細については、[依存性の注入ガイド](/guide/di)、[ドラッグ設定のインジェクショントークンAPI](api/cdk/drag-drop/CDK_DRAG_CONFIG)、[ドラッグアンドドロップ設定API](api/cdk/drag-drop/DragDropConfig)を参照してください。

### リスト間でアイテムをコピーする {#copying-items-between-lists}

デフォルトでは、アイテムがあるリストから別のリストへドラッグされると、元のリストから移動されます。ただし、ディレクティブを設定して、元のアイテムをソースリストに残したままアイテムをコピーできます。

コピーを有効にするには、`cdkDropListHasAnchor`入力を設定します。これにより、`cdkDropList`は元のコンテナーにとどまり、アイテムと一緒には移動しない「アンカー」要素を作成します。ユーザーがアイテムを元のコンテナーに戻した場合、アンカーは自動的に削除されます。アンカー要素は、`.cdk-drag-anchor` CSSクラスを対象にしてスタイル設定できます。

`cdkDropListHasAnchor`と`cdkDropListSortingDisabled`を組み合わせることで、ユーザーがソースリストを並べ替えられないままアイテムをコピーできるリストを構築できます（たとえば、商品リストとショッピングカート）。

<docs-code-multifile preview path="adev/src/content/examples/drag-drop/src/copy-list/app/app.ts">
  <docs-code header="app.html" path="adev/src/content/examples/drag-drop/src/copy-list/app/app.html"/>
  <docs-code header="app.ts" path="adev/src/content/examples/drag-drop/src/copy-list/app/app.ts"/>
  <docs-code header="app.css" path="adev/src/content/examples/drag-drop/src/copy-list/app/app.css"/>
</docs-code-multifile>

## アニメーションをカスタマイズする {#customize-animations}

ドラッグアンドドロップは、次の両方に対してアニメーションをサポートします。

- リスト内でドラッグ可能要素を並べ替える
- ユーザーがドラッグ可能要素をドロップした位置から、リスト内の最終位置へ移動する

アニメーションを設定するには、transformプロパティを対象にするCSS transitionを定義します。アニメーションには次のクラスを使用できます。

| CSSクラス名       | transitionを追加した結果                                                                                                                                                                           |
| :------------------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| .cdk-drag           | ドラッグ可能要素が並べ替えられている間、その要素をアニメーションします。                                                                                                                             |
| .cdk-drag-animating | ドラッグ可能要素を、ドロップされた位置から`cdkDropList`内の最終位置へアニメーションします。<br><br>このCSSクラスは、ドラッグアクションが停止したときにのみ`cdkDrag`要素に適用されます。 |

## スタイリング {#styling}

`cdkDrag`ディレクティブと`cdkDropList`ディレクティブはどちらも、機能に必要な必須スタイルだけを適用します。アプリケーションは、指定されたCSSクラスを対象にしてスタイルをカスタマイズできます。

| CSSクラス名             | 説明                                                                                                                                                                                                                                                                                             |
| :----------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| .cdk-drop-list           | `cdkDropList`コンテナー要素のセレクターです。                                                                                                                                                                                                                                                      |
| .cdk-drag                | `cdkDrag`要素のセレクターです。                                                                                                                                                                                                                                                                        |
| .cdk-drag-disabled       | 無効化された`cdkDrag`要素のセレクターです。                                                                                                                                                                                                                                                               |
| .cdk-drag-handle         | `cdkDragHandle`のホスト要素のセレクターです。                                                                                                                                                                                                                                                   |
| .cdk-drag-preview        | ドラッグプレビュー要素のセレクターです。これは、ユーザーがソート可能なリスト内で要素をドラッグするときにカーソルの近くに表示される要素です。<br><br>`*cdkDragPreview`によるカスタムテンプレートでカスタマイズしない限り、この要素はドラッグされている要素とまったく同じ見た目になります。 |
| .cdk-drag-placeholder    | ドラッグプレースホルダー要素のセレクターです。これは、ドラッグアクションが終了した後にドラッグ可能要素がドラッグされる先の場所に表示される要素です。<br><br>cdkDragPlaceholderディレクティブでカスタマイズしない限り、この要素は並べ替えられている要素とまったく同じ見た目になります。 |
| .cdk-drop-list-dragging  | 現在ドラッグされているドラッグ可能要素を持つ`cdkDropList`コンテナー要素のセレクターです。                                                                                                                                                                                                      |
| .cdk-drop-list-disabled  | 無効化された`cdkDropList`コンテナー要素のセレクターです。                                                                                                                                                                                                                                        |
| .cdk-drop-list-receiving | 現在ドラッグされている接続済みドロップリストから受け取れるドラッグ可能要素を持つ`cdkDropList`コンテナー要素のセレクターです。                                                                                                                                                    |
| .cdk-drag-anchor         | `cdkDropListHasAnchor`が有効なときに作成されるアンカー要素のセレクターです。この要素は、ドラッグされたアイテムが開始した位置を示します。                                                                                                                                        |

## スクロール可能なコンテナー内でのドラッグ {#dragging-in-a-scrollable-container}

ドラッグ可能アイテムがスクロール可能なコンテナー内（たとえば、`overflow: auto`を持つ`div`）にある場合、そのスクロール可能コンテナーに`cdkScrollable`ディレクティブがない限り、自動スクロールは機能しません。これがないと、CDKはドラッグ操作中にコンテナーのスクロール動作を検出または制御できません。

## 他のコンポーネントとの統合 {#integrations-with-other-components}

CDKのドラッグアンドドロップ機能は、さまざまなコンポーネントと統合できます。一般的なユースケースには、ソート可能な`MatTable`コンポーネントやソート可能な`MatTabGroup`コンポーネントがあります。
