# Angularアニメーションパッケージからの移行

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

<docs-code header="open-close.ts" path="adev/src/content/examples/animations/src/app/open-close.ts" region="state1"/>

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

<docs-code-multifile>
    <docs-code header="open-close.ts" path="adev/src/content/examples/animations/src/app/animations-package/open-close.ts" />
    <docs-code header="open-close.html" path="adev/src/content/examples/animations/src/app/animations-package/open-close.html" />
    <docs-code header="open-close.css" path="adev/src/content/examples/animations/src/app/animations-package/open-close.css"/>
</docs-code-multifile>

より高度な制御が必要な場合は [Web Animations API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API) を利用します。
親子で同時にアニメーションする場合は、イベントバブリングによる誤検知に注意します。

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/open-close.ts">
    <docs-code header="open-close.ts" path="adev/src/content/examples/animations/src/app/native-css/open-close.ts" />
    <docs-code header="open-close.html" path="adev/src/content/examples/animations/src/app/native-css/open-close.html" />
    <docs-code header="open-close.css" path="adev/src/content/examples/animations/src/app/native-css/open-close.css"/>
</docs-code-multifile>

### 特定要素のターゲティング {#targeting-specific-elements}

`query()` の代わりにCSSセレクターを使います。
子要素への適用タイミングはテンプレートのクラス/スタイルバインディングで制御します。

### Stagger相当 {#stagger}

`stagger()` は `animation-delay` または `transition-delay` で再現できます。
リスト項目ごとに遅延をずらしてカスケード表示を作ります。

### 並列アニメーション {#parallel-animations}

The animations package offers the ability to animate things that have been historically difficult to animate, like animating a set height to `height: auto`. You can now do this with pure CSS as well.

#### With Animations Package

<docs-code-multifile>
    <docs-code header="auto-height.ts" path="adev/src/content/examples/animations/src/app/animations-package/auto-height.ts" />
    <docs-code header="auto-height.html" path="adev/src/content/examples/animations/src/app/animations-package/auto-height.html" />
    <docs-code header="auto-height.css" path="adev/src/content/examples/animations/src/app/animations-package/auto-height.css" />
</docs-code-multifile>

You can use css-grid to animate to auto height.

#### With Native CSS

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/auto-height.ts">
    <docs-code header="auto-height.ts" path="adev/src/content/examples/animations/src/app/native-css/auto-height.ts" />
    <docs-code header="auto-height.html" path="adev/src/content/examples/animations/src/app/native-css/auto-height.html" />
    <docs-code header="auto-height.css" path="adev/src/content/examples/animations/src/app/native-css/auto-height.css"  />
</docs-code-multifile>

If you don't have to worry about supporting all browsers, you can also check out `calc-size()`, which is the true solution to animating auto height. See [MDN's docs](https://developer.mozilla.org/en-US/docs/Web/CSS/calc-size) and (this tutorial)[https://frontendmasters.com/blog/one-of-the-boss-battles-of-css-is-almost-won-transitioning-to-auto/] for more information.

### Animate entering and leaving a view

The animations package offered the previously mentioned pattern matching for entering and leaving but also included the shorthand aliases of `:enter` and `:leave`.

#### With Animations Package

<docs-code-multifile>
    <docs-code header="insert-remove.ts" path="adev/src/content/examples/animations/src/app/animations-package/insert-remove.ts" />
    <docs-code header="insert-remove.html" path="adev/src/content/examples/animations/src/app/animations-package/insert-remove.html" />
    <docs-code header="insert-remove.css" path="adev/src/content/examples/animations/src/app/animations-package/insert-remove.css" />
</docs-code-multifile>

#### With Native CSS

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/insert.ts">
    <docs-code header="insert.ts" path="adev/src/content/examples/animations/src/app/native-css/insert.ts" />
    <docs-code header="insert.html" path="adev/src/content/examples/animations/src/app/native-css/insert.html" />
    <docs-code header="insert.css" path="adev/src/content/examples/animations/src/app/native-css/insert.css"  />
</docs-code-multifile>

#### With Native CSS

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/remove.ts">
    <docs-code header="remove.ts" path="adev/src/content/examples/animations/src/app/native-css/remove.ts" />
    <docs-code header="remove.html" path="adev/src/content/examples/animations/src/app/native-css/remove.html" />
    <docs-code header="remove.css" path="adev/src/content/examples/animations/src/app/native-css/remove.css"  />
</docs-code-multifile>

For more information on `animate.enter` and `animate.leave`, see the [Enter and Leave animations guide](guide/animations).

### Animating increment and decrement

Along with the aforementioned `:enter` and `:leave`, there's also `:increment` and `:decrement`. You can animate these also by adding and removing classes. Unlike the animation package built-in aliases, there is no automatic application of classes when the values go up or down. You can apply the appropriate classes programmatically. Here's an example:

#### With Animations Package

<docs-code-multifile>
    <docs-code header="increment-decrement.ts" path="adev/src/content/examples/animations/src/app/animations-package/increment-decrement.ts" />
    <docs-code header="increment-decrement.html" path="adev/src/content/examples/animations/src/app/animations-package/increment-decrement.html" />
    <docs-code header="increment-decrement.css" path="adev/src/content/examples/animations/src/app/animations-package/increment-decrement.css" />
</docs-code-multifile>

#### With Native CSS

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/increment-decrement.ts">
    <docs-code header="increment-decrement.ts" path="adev/src/content/examples/animations/src/app/native-css/increment-decrement.ts" />
    <docs-code header="increment-decrement.html" path="adev/src/content/examples/animations/src/app/native-css/increment-decrement.html" />
    <docs-code header="increment-decrement.css" path="adev/src/content/examples/animations/src/app/native-css/increment-decrement.css" />
</docs-code-multifile>

### Parent / Child Animations

Unlike the animations package, when multiple animations are specified within a given component, no animation has priority over another and nothing blocks any animation from firing. Any sequencing of animations would have to be handled by your definition of your CSS animation, using animation / transition delay, and / or using `animationend` or `transitionend` to handle adding the next css to be animated.

### Disabling an animation or all animations

With native CSS animations, if you'd like to disable the animations that you've specified, you have multiple options.

1. Create a custom class that forces animation and transition to `none`.

```css
.no-animation {
  animation: none !important;
  transition: none !important;
}
```

Applying this class to an element prevents any animation from firing on that element. You could alternatively scope this to your entire DOM or section of your DOM to enforce this behavior. However, this prevents animation events from firing. If you are awaiting animation events for element removal, this solution won't work. A workaround is to set durations to 1 millisecond instead.

2. Use the [`prefers-reduced-motion`](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion) media query to ensure no animations play for users that prefer less animation.

3. Prevent adding animation classes programatically

### Animation Callbacks

The animations package exposed callbacks for you to use in the case that you want to do something when the animation has finished. Native CSS animations also have these callbacks.

[`OnAnimationStart`](https://developer.mozilla.org/en-US/docs/Web/API/Element/animationstart_event)  
[`OnAnimationEnd`](https://developer.mozilla.org/en-US/docs/Web/API/Element/animationend_event)  
[`OnAnimationIteration`](https://developer.mozilla.org/en-US/docs/Web/API/Element/animationitration_event)  
[`OnAnimationCancel`](https://developer.mozilla.org/en-US/docs/Web/API/Element/animationcancel_event)

[`OnTransitionStart`](https://developer.mozilla.org/en-US/docs/Web/API/Element/transitionstart_event)  
[`OnTransitionRun`](https://developer.mozilla.org/en-US/docs/Web/API/Element/transitionrun_event)  
[`OnTransitionEnd`](https://developer.mozilla.org/en-US/docs/Web/API/Element/transitionend_event)  
[`OnTransitionCancel`](https://developer.mozilla.org/en-US/docs/Web/API/Element/transitioncancel_event)

The Web Animations API has a lot of additional functionality. [Take a look at the documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API) to see all the available animation APIs.

NOTE: Be aware of bubbling issues with these callbacks. If you are animating children and parents, the events bubble up from children to parents. Consider stopping propagation or looking at more details within the event to determine if you're responding to the desired event target rather than an event bubbling up from a child node. You can examine the `animationname` property or the properties being transitioned to verify you have the right nodes.

## Complex Sequences

The animations package has built-in functionality for creating complex sequences. These sequences are all entirely possible without the animations package.

### Targeting specific elements

In the animations package, you could target specific elements by using the `query()` function to find specific elements by a CSS class name, similar to [`document.querySelector()`](https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector). This is unnecessary in a native CSS animation world. Instead, you can use your CSS selectors to target sub-classes and apply any desired `transform` or `animation`.

To toggle classes for child nodes within a template, you can use class and style bindings to add the animations at the right points.

### Stagger()

The `stagger()` function allowed you to delay the animation of each item in a list of items by a specified time to create a cascade effect. You can replicate this behavior in native CSS by utilizing `animation-delay` or `transition-delay`. Here is an example of what that CSS might look like.

#### With Animations Package

<docs-code-multifile>
    <docs-code header="stagger.ts" path="adev/src/content/examples/animations/src/app/animations-package/stagger.ts" />
    <docs-code header="stagger.html" path="adev/src/content/examples/animations/src/app/animations-package/stagger.html" />
    <docs-code header="stagger.css" path="adev/src/content/examples/animations/src/app/animations-package/stagger.css" />
</docs-code-multifile>

#### With Native CSS

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/stagger.ts">
    <docs-code header="stagger.ts" path="adev/src/content/examples/animations/src/app/native-css/stagger.ts" />
    <docs-code header="stagger.html" path="adev/src/content/examples/animations/src/app/native-css/stagger.html" />
    <docs-code header="stagger.css" path="adev/src/content/examples/animations/src/app/native-css/stagger.css" />
</docs-code-multifile>

### Parallel Animations

The animations package has a `group()` function to play multiple animations at the same time. In CSS, you have full control over animation timing. If you have multiple animations defined, you can apply all of them at once.

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

#### With Animations Package

<docs-code-multifile>
    <docs-code header="reorder.ts" path="adev/src/content/examples/animations/src/app/animations-package/reorder.ts" />
    <docs-code header="reorder.html" path="adev/src/content/examples/animations/src/app/animations-package/reorder.html" />
    <docs-code header="reorder.css" path="adev/src/content/examples/animations/src/app/animations-package/reorder.css" />
</docs-code-multifile>

#### With Native CSS

<docs-code-multifile preview path="adev/src/content/examples/animations/src/app/native-css/reorder.ts">
    <docs-code header="reorder.ts" path="adev/src/content/examples/animations/src/app/native-css/reorder.ts" />
    <docs-code header="reorder.html" path="adev/src/content/examples/animations/src/app/native-css/reorder.html" />
    <docs-code header="reorder.css" path="adev/src/content/examples/animations/src/app/native-css/reorder.css" />
</docs-code-multifile>

## Migrating usages of AnimationPlayer

The `AnimationPlayer` class allows access to an animation to do more advanced things like pause, play, restart, and finish an animation through code. All of these things can be handled natively as well.

You can retrieve animations off an element directly using [`Element.getAnimations()`](https://developer.mozilla.org/en-US/docs/Web/API/Element/getAnimations). This returns an array of every [`Animation`](https://developer.mozilla.org/en-US/docs/Web/API/Animation) on that element. You can use the `Animation` API to do much more than you could with what the `AnimationPlayer` from the animations package offered. From here you can `cancel()`, `play()`, `pause()`, `reverse()` and much more. This native API should provide everything you need to control your animations.

## Route Transitions

You can use view transitions to animate between routes. See the [Route Transition Animations Guide](guide/routing/route-transition-animations) to get started.
