<template>
    <el-tooltip class="item" effect="dark" :content="text" placement="bottom" :enterable='false' 
    :style="{'border-color':bcolor}" >
        <div class="tubdax" id="wafght" ref='pTag'
        @mouseover="itemMouseover"
        @mouseout="itemMouseout">
            <img :src="imgSrc" alt="">
        </div>
    </el-tooltip>

</template>

<script>
let defaultImgSrc = ''
export default {
  name: 'IconButton',
  props: {
    text: { type: String, default: '' }, // 字符内容
    img: { type: String, default: '' }, // 图片
    bcolor: { type: String, default: '#DADADA' }, // 颜色
    disabled: { type: String, default: '' }, // 背景颜色
    bjcolors: { type: String, default: '' }, // 背景颜色
  },
  data() {
    return {
      imgSrc: require('@/assets/img/' + this.img)
    }
  },
  methods: {
    itemMouseover(){
            this.$refs.pTag.style.backgroundColor = this.bjcolors || '#f9f9f9' // this.colors
            const _imgSrc = this.img.split('.')
            this.imgSrc = require('@/assets/img/' + _imgSrc[0]+'hover.'+_imgSrc[1])
    },
    itemMouseout(){
        this.$refs.pTag.style.backgroundColor = ''
        this.imgSrc = require('@/assets/img/' + this.img)
    },

  },
}
</script>
<style>  
    .tubdax{
        width: 32px;
        height: 32px;
        border-radius:50%;
        border: 1px solid #DADADA ;
        display: flex;
        justify-content: center;
        align-items: center;
        margin-left: 16px;
        margin-top: 11px;
        margin-bottom: 11px;
        cursor: pointer;
    }
    .tubdax:hover{
        background-color: #383943;
    }
    .tubdax img{
        width: 16px;
        height: 16px;
    }
    .el-tooltip__popper.is-dark{
        background-color: #555763;
    }
    .el-tooltip__popper[x-placement^=bottom] .popper__arrow::after{
        border-bottom-color: #555763 !important;
    }
    .el-tooltip__popper.is-dark{
        color: #F0F0F0;
        font-size: 14px;
    }
    .el-tooltip__popper{
        padding: 13px 22px;
    }
</style>