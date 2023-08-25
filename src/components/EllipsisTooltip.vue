<template>
  <el-tooltip
    ref="tlp"
    :content="text"
    effect="light"
    :disabled="!tooltipFlag"
    placement="top"
    class="tooltip">
    <div class="qqq" @mouseenter="visibilityChange($event)">{{ text }}</div>
  </el-tooltip>
</template>

<script>
export default {
  name: 'EllipsisTooltip',
  props: {
    text: { type: String, default: '' }, // 字符内容
  },
  data() {
    return {
      tooltipFlag: false
    }
  },
  methods: {
    // tooltip的可控
    visibilityChange(event) {
      const ev = event.target
        if(ev.scrollWidth > ev.offsetWidth){
            this.tooltipFlag = true
        }else {
            this.tooltipFlag = false
        }
    }
  }
}
</script>
<style>  
    .qqq{
        /* line-height: 1.3; */
        /* height: 20px; */
        /* text-align: center; */
        /* line-height: 20px; */
        /* width: 136px; */
        width: 100%;
        text-align: left;
        overflow:hidden;
        text-overflow:ellipsis;
        white-space:nowrap;
    }
</style>