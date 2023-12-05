<template>
    <div class="image-container" v-if="dialogVisible">
        <img :src="imgSrc" alt="Image Preview" class="preview-image">
        <img :src="require('@/assets/img/pre-close.png')" @click="handleClose()" class="close-img">
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
        max-width: 100%;
        height: 100vh;
        object-fit: contain;
        /* 图片保持原始比例 */
    }

    .close-img {
        width: 60px;
        height: 60px;
        position: fixed;
        z-index: 1000;
        top: 10px;
        right: 20%;
        cursor: pointer;
    }
}
</style>