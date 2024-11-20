<template>
    <div class="keyboard" :style="{ left: position.x + 'px', top: position.y + 'px' }" @mousedown="startDrag"
        ref="keyboard">
        <div class="keyboard-header" @mousedown="startDrag">
            <span>键盘</span>
            <i class="el-icon-close" @click="$emit('close')"></i>
        </div>

        <div class="keyboard-content">
            <!-- 数字键 -->
            <div class="keyboard-row">
                <div class="key" v-for="n in 10" :key="n - 1" @click="emitKey(n - 1)">{{ n - 1 }}</div>
            </div>

            <!-- 字母键第一行 -->
            <div class="keyboard-row">
                <div class="key" v-for="letter in 'qwertyuiop'" :key="letter" @click="emitKey(letter)">
                    {{ letter }}
                </div>
            </div>

            <!-- 字母键第二行 -->
            <div class="keyboard-row">
                <div class="key" v-for="letter in 'asdfghjkl'" :key="letter" @click="emitKey(letter)">
                    {{ letter }}
                </div>
            </div>

            <!-- 字母键第三行 -->
            <div class="keyboard-row">
                <div class="key" v-for="letter in 'zxcvbnm'" :key="letter" @click="emitKey(letter)">
                    {{ letter }}
                </div>
            </div>

            <!-- 功能键 -->
            <div class="keyboard-row">
                <div class="key function-key" @click="emitKey('backspace')">回退</div>
                <div class="key function-key" @click="emitKey('clear')">清空</div>
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
                x: 100,
                y: 100
            },
            isDragging: false,
            dragOffset: {
                x: 0,
                y: 0
            }
        }
    },
    methods: {
        emitKey(key) {
            this.$emit('key-press', key)
        },

        startDrag(e) {
            this.isDragging = true
            this.dragOffset = {
                x: e.clientX - this.position.x,
                y: e.clientY - this.position.y
            }

            document.addEventListener('mousemove', this.onDrag)
            document.addEventListener('mouseup', this.stopDrag)
        },

        onDrag(e) {
            if (!this.isDragging) return

            this.position = {
                x: e.clientX - this.dragOffset.x,
                y: e.clientY - this.dragOffset.y
            }
        },

        stopDrag() {
            this.isDragging = false
            document.removeEventListener('mousemove', this.onDrag)
            document.removeEventListener('mouseup', this.stopDrag)
        }
    },

    beforeDestroy() {
        document.removeEventListener('mousemove', this.onDrag)
        document.removeEventListener('mouseup', this.stopDrag)
    }
}
</script>

<style scoped>
.keyboard {
    position: fixed;
    width: 500px;
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 4px;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
    user-select: none;
    z-index: 9999;
}

.keyboard-header {
    padding: 8px 12px;
    background: #f5f5f5;
    border-bottom: 1px solid #ddd;
    cursor: move;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.keyboard-content {
    padding: 12px;
}

.keyboard-row {
    display: flex;
    justify-content: center;
    margin-bottom: 8px;
}

.key {
    width: 40px;
    height: 40px;
    margin: 0 4px;
    border: 1px solid #ddd;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    background: #fff;
    transition: all 0.2s;
}

.key:hover {
    background: #f5f5f5;
}

.key:active {
    background: #e8e8e8;
    transform: translateY(1px);
}

.function-key {
    width: 80px;
}

.el-icon-close {
    cursor: pointer;
    padding: 4px;
}

.el-icon-close:hover {
    background: rgba(0, 0, 0, 0.1);
    border-radius: 50%;
}
</style>