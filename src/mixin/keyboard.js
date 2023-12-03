// 写一个mixin,支持显示隐藏键盘,具体实现可以参照以下注释
// 使用方法:在需要使用的页面引入该mixin,并在页面中定义ref="input"的input框,并在mounted中调用keyboardShow('input')方法,在页面离开时调用keyboardLeave()方法
// 该mixin仅支持android,ios端无效
// 该mixin仅支持在app中使用,在浏览器中无效
export const keyboardMixins = {
    methods: {
        keyboardShow(refString) {
            // if (
            //     window.atool
            //     && window.atool.getTermType() == "android" &&
            //     ("showSoftInput" in window.atool)
            // ) {
            //     atool.showSoftInput();
            //     atool.executeJs(`this.$refs.${refString}.focus()`)
        
            // }
        },
        keyboardLeave() {
            // setTimeout(() => {
            //     if (
            //     window.atool
            //     && window.atool.getTermType() == "android" &&
            //     ("hideSoftInput" in window.atool)
            //     ) {
            //     atool.hideSoftInput();
            //     atool.restart();
            //     }
            // }, 10)
        },
    }
}
