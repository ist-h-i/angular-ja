# Angularアニメーションパッケージからの移行 {#migrating-away-from-angulars-animations-package}

`@angular/animations`はAngular v20.2で非推奨になりました。
同時に導入された `animate.enter` と `animate.leave`、およびネイティブCSSを使うことで、従来のアニメーション実装を置き換えられます。
`@angular/animations`を削除するとJavaScriptバンドルを小さくでき、CSSアニメーションのハードウェアアクセラレーションによる性能上の利点も得られます。
このページは、`@angular/animations` ベースの実装をネイティブCSSへ段階的に移すための要点をまとめた要約です。

## ネイティブCSSでアニメーションを書く {#how-to-write-animations-in-native-css}

ネイティブCSSアニメーションが初めての場合は、まず次の資料で基本を確認します。

- [MDN: Using CSS animations](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_animations/Using_CSS_animations)
- [W3Schools: CSS3 Animations](https://www.w3schools.com/css/css3_animations.asp)
- [The Complete CSS Animations Tutorial](https://www.lambdatest.com/blog/css-animations-tutorial/)
- [CSS Animation for Beginners](https://thoughtbot.com/blog/css-animation-for-beginners)

## 再利用可能なアニメーションを作る {#creating-reusable-animations}

`animation()` 関数で共通化していたパターンは、共通CSSファイルに `@keyframes` やクラスを定義して置き換えます。
コンポーネント側ではクラスを付け外しするだけで再利用できます。

## トランジションをアニメーションさせる {#animating-a-transition}

### 状態とスタイルのアニメーション {#animating-state-and-styles}

`state()` で定義していた状態は、CSSクラス（例: `open` / `closed`）として表現します。
要素のクラスを切り替えることで、同等の状態遷移を実現できます。

### トランジション時間とイージング {#transitions-timing-and-easing}

`animate()`のduration / delay / easingは、次のCSSプロパティで対応できます。

- `animation-duration` / `animation-delay` / `animation-timing-function`
- `transition-duration` / `transition-delay` / `transition-timing-function`
- `animation` / `transition` のショートハンド

### アニメーションのトリガー {#triggering-an-animation}

`trigger()` の定義は不要です。
クラスまたはスタイルの切り替えをトリガーとして使うことで、より少ないコードで同じ振る舞いを実装できます。

## トランジションとトリガー {#transition-and-triggers}

### 定義済み状態とワイルドカード一致 {#predefined-state-and-wildcard-matching}

`open => closed` や `* => void` のような状態式は、ネイティブCSSでは必須ではありません。
適用したクラスとセレクターに応じて、`transition` や `@keyframes` を切り替えます。
必要に応じて `@starting-style` でDOM挿入直後の見た目を制御します。

### ワイルドカードによる自動プロパティ計算 {#automatic-property-calculation-with-wildcards}

`height: auto` への遷移のような難しいケースも、CSS Gridを使って実装できます。
ブラウザサポート要件が許す場合は `calc-size()` も有力な選択肢です。

### 要素の挿入・削除をアニメーションする {#animate-entering-and-leaving-a-view}

`:enter` / `:leave` 相当は `animate.enter` / `animate.leave` で実装します。
詳細は [Enter and Leave animations guide](guide/animations) を参照してください。

### 増減（increment/decrement）のアニメーション {#animating-increment-and-decrement}

`:increment` / `:decrement` 相当は、値の増減を検知して適切なクラスをプログラム側で付与して実現します。
組み込みエイリアスの自動付与はないため、状態管理を明示的に行います。

### 親子アニメーション {#parent-child-animations}

Angularアニメーションのような優先制御はありません。
順序制御が必要な場合は、`animation-delay` / `transition-delay` や `animationend` / `transitionend` イベントを使って連鎖させます。

### 特定のアニメーションまたは全体を無効化する {#disabling-an-animation-or-all-animations}

無効化の代表的な方法は次のとおりです。

- `animation: none` / `transition: none` を強制するクラスを適用する。
- `prefers-reduced-motion` メディアクエリでモーション削減設定を尊重する。
- アニメーションクラス自体を付与しない。

NOTE: イベント待ちで要素削除を制御している場合は、完全無効化ではなく極小durationにする設計も検討してください。

### アニメーションコールバック {#animation-callbacks}

完了通知などはネイティブイベントで対応できます。

- `animationstart` / `animationend` / `animationiteration` / `animationcancel`
- `transitionstart` / `transitionrun` / `transitionend` / `transitioncancel`

より高度な制御が必要な場合は [Web Animations API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API) を利用します。
親子で同時にアニメーションする場合は、イベントバブリングによる誤検知に注意します。

## 複雑なシーケンス {#complex-sequences}

### 特定要素のターゲティング {#targeting-specific-elements}

`query()` の代わりにCSSセレクターを使います。
子要素への適用タイミングはテンプレートのクラス/スタイルバインディングで制御します。

### Stagger相当 {#stagger}

`stagger()` は `animation-delay` または `transition-delay` で再現できます。
リスト項目ごとに遅延をずらしてカスケード表示を作ります。

### 並列アニメーション {#parallel-animations}

`group()` の代わりに、複数アニメーションを同時に指定します。

```css
.target-element {
  animation:
    rotate 3s,
    fade-in 2s;
}
```

### 並べ替えリストのアニメーション {#animating-the-items-of-a-reordering-list}

並べ替え時の入れ替わりは、`@starting-style` や `animate.enter` / `animate.leave` の組み合わせで対応できます。
特別な専用APIは不要です。

## `AnimationPlayer` 利用箇所の移行 {#migrating-usages-of-animationplayer}

`AnimationPlayer` の再生・停止・逆再生などは、`Element.getAnimations()` で取得した `Animation` オブジェクトで代替できます。
`cancel()` / `play()` / `pause()` / `reverse()` など、より柔軟な制御が可能です。

## ルート遷移 {#route-transitions}

ルート間アニメーションはView Transitionsを利用します。
詳細は [Route Transition Animations Guide](guide/routing/route-transition-animations) を参照してください。
