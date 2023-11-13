<template>
        <div class="racte" id="wafght" ref='pTag' :style="{'border-color':bcolor, 'background-color':bjcolors, 'color': tcolor} "
        @mouseover="itemMouseover"
        @mouseout="itemMouseout"
        :class="{'drgreg':disaed}">
            <span>{{wz}}</span>
        </div>
</template>

<script>
export default {
  name: 'IconButton',
  props: {
    // text: { type: String, default: '' }, // 字符内容
    wz: { type: String, default: '' }, // 图片
    bcolor: { type: String, default: '#DADADA' }, // 颜色
    bjcolors: { type: String, default: '' }, // 背景颜色
    tcolor: { type: String, default: '#1A1A21' }, // 字体颜色
    disaed: { type: Boolean, default: false }, // 禁用
  },
  data() {
    return {
      
    }
  },    
  methods: {
    itemMouseover(){
      if(this.disaed == false){
        if(this.bjcolors == ''){
            this.$refs.pTag.style.backgroundColor = 'rgb(246, 246, 246)' // this.colors
        }else{
            this.$refs.pTag.style.backgroundColor = this.bjcolors || 'transparent' // this.bjcolors
        }
      }

    },
    itemMouseout(){
        this.$refs.pTag.style.backgroundColor = ''
    },

  }
}
</script>
<style>  
    .racte{
        border-radius:20px;
        border: 1px solid #DADADA;
        /* border: 1px solid #383943 ; */
        margin-left: 16px;
        color: #1A1A21;
        /* color: #D9D9D9; */
        padding: 10px 20px;;
        margin-top: 9px;
        margin-bottom: 9px;
        cursor: pointer;
    }
    .racte span{
        font-size: 14px;
        display: block;
        white-space: nowrap;
        line-height: 1;
        /* 文字不可选中 */
        -webkit-user-select:none;
        -moz-user-select:none;
        -ms-user-select:none;
        user-select:none;
    }
    .drgreg{
        color: #434343;
        border: 1px solid #2A2A2A ;
        /* border-color: ; */
        cursor: not-allowed;
    }
    .drgreg span{
        cursor: not-allowed;
    }
</style>