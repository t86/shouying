<template>
    <div class="keyboard" :style="{ left: position.x + 'px', top: position.y + 'px' }" 
        @mousedown="startDrag"
        @touchstart="startDrag"
        ref="keyboard">
        <div class="keyboard-header" 
            @mousedown="startDrag"
            @touchstart="startDrag">
            <span>键盘</span>
            <i class="el-icon-close" @click="handleClick('close')" @touchstart.prevent="handleClick('close')" style="font-size: 24px;"></i>
        </div>

        <div class="keyboard-content">
            <!-- 数字键 -->
            <div class="keyboard-row">
                <div class="key" v-for="n in 10" :key="n - 1" @click="handleClick('key', n - 1)" @touchstart.prevent="handleClick('key', n - 1)">{{ n - 1 }}</div>
            </div>

            <!-- 字母键第一行 -->
            <div class="keyboard-row">
                <div class="key" v-for="letter in 'qwertyuiop'" :key="letter" @click="handleClick('key', letter)" @touchstart.prevent="handleClick('key', letter)">
                    {{ letter }}
                </div>
            </div>

            <!-- 字母键第二行 -->
            <div class="keyboard-row">
                <div class="key" v-for="letter in 'asdfghjkl'" :key="letter" @click="handleClick('key', letter)" @touchstart.prevent="handleClick('key', letter)">
                    {{ letter }}
                </div>
            </div>

            <!-- 字母键第三行 -->
            <div class="keyboard-row">
                <div class="key" v-for="letter in 'zxcvbnm'" :key="letter" @click="handleClick('key', letter)" @touchstart.prevent="handleClick('key', letter)">
                    {{ letter }}
                </div>
            </div>

            <!-- 功能键 -->
            <div class="keyboard-row">
                <div class="key function-key" @click="handleClick('key', 'backspace')" @touchstart.prevent="handleClick('key', 'backspace')">回退</div>
                <div class="key function-key" @click="handleClick('key', 'clear')" @touchstart.prevent="handleClick('key', 'clear')">清空</div>
                <div class="key function-key" @click="handleClick('close')" @touchstart.prevent="handleClick('close')">确定</div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'Keyboard',
    data() {
        return {
            position: {
                x: 0,
                y: 0
            },
            isDragging: false,
            dragOffset: {
                x: 0,
                y: 0
            }
        }
    },
    methods: {
        handleClick(type, value) {
            if(type === 'key') {
                this.emitKey(value)
            } else if(type === 'close') {
                this.$emit('close')
            }
        },

        emitKey(key) {
            this.$emit('key-press', key)
        },

        startDrag(e) {
            this.isDragging = true
            
            // 处理触摸事件
            if(e.type === 'touchstart') {
                e.preventDefault() // 阻止默认行为
                e = e.touches[0] // 获取第一个触摸点
            }

            this.dragOffset = {
                x: e.clientX - this.position.x,
                y: e.clientY - this.position.y
            }

            // 同时监听鼠标和触摸事件
            document.addEventListener('mousemove', this.onDrag)
            document.addEventListener('touchmove', this.onDrag, { passive: false })
            document.addEventListener('mouseup', this.stopDrag)
            document.addEventListener('touchend', this.stopDrag)
        },

        onDrag(e) {
            if (!this.isDragging) return

            // 处理触摸事件
            if(e.type === 'touchmove') {
                e.preventDefault() // 阻止默认行为
                e = e.touches[0] // 获取第一个触摸点
            }

            // 计算新位置
            let newX = e.clientX - this.dragOffset.x
            let newY = e.clientY - this.dragOffset.y

            // 防止拖出屏幕
            const keyboard = this.$refs.keyboard
            const maxX = window.innerWidth - keyboard.offsetWidth
            const maxY = window.innerHeight - keyboard.offsetHeight

            newX = Math.max(0, Math.min(newX, maxX))
            newY = Math.max(0, Math.min(newY, maxY))

            this.position = {
                x: newX,
                y: newY
            }
        },

        stopDrag() {
            this.isDragging = false
            // 移除所有事件监听
            document.removeEventListener('mousemove', this.onDrag)
            document.removeEventListener('touchmove', this.onDrag)
            document.removeEventListener('mouseup', this.stopDrag)
            document.removeEventListener('touchend', this.stopDrag)
        },

        centerKeyboard() {
            const keyboard = this.$refs.keyboard
            if(keyboard) {
                const windowWidth = window.innerWidth
                const windowHeight = window.innerHeight
                const keyboardWidth = keyboard.offsetWidth
                const keyboardHeight = keyboard.offsetHeight

                this.position = {
                    x: (windowWidth - keyboardWidth) / 2,
                    y: (windowHeight - keyboardHeight) / 2
                }
            }
        }
    },

    mounted() {
        this.centerKeyboard()
    },

    beforeDestroy() {
        // 确保移除所有事件监听
        document.removeEventListener('mousemove', this.onDrag)
        document.removeEventListener('touchmove', this.onDrag)
        document.removeEventListener('mouseup', this.stopDrag)
        document.removeEventListener('touchend', this.stopDrag)
    }
}
</script>

<style scoped>
.keyboard {
    position: fixed;
    width: 460px;
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 4px;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
    user-select: none;
    z-index: 2100;
    touch-action: none; /* 防止触摸事件引起页面滚动 */
}

.keyboard-header {
    padding: 10px 16px;
    background: #f5f5f5;
    border-bottom: 1px solid #ddd;
    cursor: move;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 16px;
}

.keyboard-content {
    padding: 10px;
}

.keyboard-row {
    display: flex;
    justify-content: center;
    margin-bottom: 6px;
}

.key {
    width: 36px;
    height: 36px;
    margin: 0 3px;
    border: 1px solid #ddd;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    background: #fff;
    transition: all 0.2s;
    font-size: 16px;
    -webkit-tap-highlight-color: transparent; /* 去除点击高亮 */
    touch-action: manipulation; /* 优化触摸操作 */
}

.key:hover {
    background: #f5f5f5;
}

.key:active {
    background: #e8e8e8;
    transform: translateY(1px);
}

.function-key {
    width: 65px;
    font-size: 14px;
    margin: 0 4px;
}

.el-icon-close {
    cursor: pointer;
    padding: 8px;
    font-size: 24px;
}

.el-icon-close:hover {
    background: rgba(0, 0, 0, 0.1);
    border-radius: 50%;
}
</style>