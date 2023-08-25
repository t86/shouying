<template>
    <div class="smgr">
        <router-view/>        
    </div>
</template>
<script>
export default {
    
}
</script>
<style scoped>
    .smgr{
        /* width: calc(100% - 100px);
        min-height: calc(100% - 60px);
        padding: 20px 40px;
        margin: 10px 10px 0px;
        background-color:#1A1A20 ;
        border-radius: 10px; */
        height: calc(100% - 20px);
        width: calc(100% - 20px);
        min-height: calc(100% - 20px);
        margin: 10px 10px 0px;
        padding: 10px;
        box-sizing: border-box;
        background-color:#f9f9f9 ;
        border-radius: 10px;
    }
    .el-checkbox__inner{
      background-color: rgba(0,0, 0, 0);
    }
    /* input 高度 */
    .el-input__inner{
      height: 34px;
      line-height: 34px;
    }
    /* 下拉框icon 位置 */
    .el-input__icon{
      line-height: 34px;
    }
    /* .el-select-dropdown{
      background-color: rgba(255, 255, 255, 0);
    } */
    /* 改变框颜色 */
     .el-input__inner, .el-textarea__inner{
        border: 1px solid rgb(217, 217, 217)  !important; 
    }
    /* 获取焦点后颜色 */
    .el-input__inner:focus ,.el-textarea__inner:focus{
      border-color: #409EFF !important;  
    }
    /* input 文字居中 */
    .Writmiddle .el-input__inner{
        text-align: center;
        border: 1px solid #1e3deb  !important;
    }
    /*原生   定义滚动条高宽及背景 高宽分别对应横竖滚动条的尺寸*/
    table tbody::-webkit-scrollbar {
      width: 6px;
      height: 12px;
      background-color: #1a1a20;
    }
    /*定义滑块 圆角*/
    table tbody::-webkit-scrollbar-thumb {
      background-color: #5f5f63;
      border-radius: 5px;
    }
    /*原生   定义滚动条高宽及背景 高宽分别对应横竖滚动条的尺寸*/
    ::-webkit-scrollbar {
      width: 6px;
      height: 6px;
      background-color: #1a1a20;
    }
    /*定义滑块 圆角*/
    ::-webkit-scrollbar-thumb {
      background-color: #5f5f63;
      border-radius: 5px;
    }
    /*解决表格固定列时的压样式问题 */
    .table__fixed {
      height: calc(100% - 12px) !important;  
    }


    /*el组件定义滚动条高宽及背景 高宽分别对应横竖滚动条的尺寸*/
    .el-table ::-webkit-scrollbar {
      width: 6px;
      height: 6px;
      background-color: #1a1a20;
    }
    .el-table ::-webkit-scrollbar-thumb {
      background-color: #5f5f63;
      border-radius: 5px;
    }
    .el-table__fixed {
      height: calc(100% - 12px) !important;  
    }
    /* 弹窗蒙层 */
    .v-modal{
      background-color: rgba(0, 0, 0, 0.25);
    }

    /* 反审核成功，不可选 */
    .el-checkbox__input.is-disabled .el-checkbox__inner{
        background-color: rgba(255, 255, 255, 0.4);
        border: 1px solid rgb(190, 190, 190);
    }
    .el-checkbox__label{
        color: #D9D9D9;
    }
    .el-checkbox__input.is-disabled + span.el-checkbox__label{
        color: rgb(89, 89, 89);
    }


    /* 文本域不显示下拉 */
    .el-textarea__inner{
        resize: none;
    }
    /*定义滚动条高宽及背景 高宽分别对应横竖滚动条的尺寸*/
    .el-textarea__inner::-webkit-scrollbar {
      width: 6px;
      height: 12px;
      background-color: #1a1a20;
    }
    .el-textarea__inner::-webkit-scrollbar-thumb {
      background-color: #5f5f63;
      border-radius: 5px;
    }
    /* input和多行输入框 */
    .el-input__inner::-webkit-input-placeholder ,.el-textarea__inner::-webkit-input-placeholder{
        color: rgb(104, 104, 109);
    }
    /* 按钮 */
    .el-button{
      padding: 9px 20px;
    }
    .el-button--primary{
        background-color: #2170ff;
        border-color: #2170ff;
        color: #D9D9D9;
    }
    /* 取消按钮 */
    .el-button--default{
        background-color: #2A3450 ;
        border: 1px solid #7298FF;
        color: #D9D9D9;
    }    

    /* 文字超出提示 */
    .el-tooltip__popper.is-light{
        background-color: #BCBDC3;   
        color: #1A1A20;
        max-width: 400px;
    }
    .el-tooltip__popper.is-light[x-placement^="top"]{
      margin-bottom: 5px;
    }
    .el-tooltip__popper.is-light[x-placement^="top"] .popper__arrow{
        border-top-color: #BCBDC3 !important;
    }
    .el-tooltip__popper.is-light[x-placement^=top] .popper__arrow::after{
        border-top-color: #BCBDC3 !important;
    }
    /* 改变所有选择框颜色 */
    /* 多选 */
    .el-checkbox__input.is-checked .el-checkbox__inner, .el-checkbox__input.is-indeterminate .el-checkbox__inner {
      background-color: #2170ff;
      border-color: #2170ff!important;
    }
    /* 单选 */
    .el-radio__input.is-checked .el-radio__inner {
      background-color: #2170ff;
      border-color: #2170ff!important;
    }
    /* 输入框禁用颜色 */
    .el-input.is-disabled .el-input__inner{
        background-color: rgba(255, 255, 255, 0.075);
    }
    /* 单选框框文字颜色 */
    .el-radio{
        color: #D9D9D9 ;
    }
    /* 去掉双击蓝色阴影 */
    .el-radio-button{
      box-shadow: none !important;
    }
    /* 弹窗底部颜色更改 */
    .el-dialog__footer{
        background-color: #1D1D24 !important;
    }
    /* 弹窗头部颜色更改 */
    .el-dialog__header{
        background-color: #22232B !important;
    }
    /*  */
    q{
      box-sizing: border-box;
    }

</style>