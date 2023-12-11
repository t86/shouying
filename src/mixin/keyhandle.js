// 写一个mixin,支持显示隐藏键盘,具体实现可以参照以下注释
// 使用方法:在需要使用的页面引入该mixin,并在页面中定义ref="input"的input框,并在mounted中调用keyboardShow('input')方法,在页面离开时调用keyboardLeave()方法
// 该mixin仅支持android,ios端无效
// 该mixin仅支持在app中使用,在浏览器中无效
export const keyHandle = {
    mounted() {
        setTimeout(() => {
            // 给document绑定onkeydown事件
            document.onkeydown = this.keyHandle;
    })
    },
    // 页面销毁时解绑onkeydown事件
    beforeDestroy() {
        // Unbind onkeydown event from document
        document.onkeydown = null;
    },
    methods: {
        keyHandle(event) {
            // 如果是触发的回车，并且有getTableData这个方法,则执行
            if (event.keyCode == 13 && this.getTableData) {
                this.getTableData();
            }

        },

    }
}
