<template>
    <div class="image-container" v-if="dialogVisible" @click="handleClose()">
        <img :src="imgSrc" alt="Image Preview" class="preview-image">
    </div>
</template>

<script>
export default {
    name: 'ImagePreview',
    props: {
        imgSrc: { type: String, default: '' }, // 图片
        dialogVisible: { type: Boolean, default: false }, // 显示隐藏
    },
    data() {
        return {
            imgSrc: "",
            dialogVisible: false
        }
    },
    methods: {
        handleClose() {
            this.$emit('handleCloseClick');
        }
    },
}
</script>
<style scoped lang="less">
.image-container {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100vh;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 999;

    .preview-image {
        min-width: 30%;
        max-width: 100%;
        max-height: 100%;
        object-fit: cover;
        /* 图片保持原始比例 */
    }
}
</style>