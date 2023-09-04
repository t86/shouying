<template>
    <div>
        <div v-for="(stair,i) in classify" :key="i" class="stair" :style="{'padding-left':`${+stair.l + 12}px`}">
            <el-collapse v-if="stair.subs" v-model="deptIds[stair.l]" @change="handleChange($event, stair)" accordion>
                <el-collapse-item :name="stair.id+''">
                    <span slot="title"
                          class="collapse-title" style="width: calc(100% - 18px);">
                        <img class="icons" src="@/assets/img/file_list.png" alt="">
                        <router-link :to="`/BMS/dept/emp/${stair.id}`" class="routerlinkyus"
                                     style="width: calc(100% - 18px);">
                            <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                        </router-link>
                    </span>
                    <!-- 递归组件是指在组件内部调用组件自身 -->
                    <div v-if="stair.subs">
                        <menus :classify="stair.subs" :deptIds="deptIds" :gaibland="gaibland" @onChange="handleChange"/>
                    </div>
                </el-collapse-item>
            </el-collapse>

            <span v-if="!stair.subs" slot="title"
                  :style="{'background-color':gaibland==stair.id?'#d7e9ff':'','padding-left':'17px','border-radius':'6px'}"
                  class="collapse-title" style="width: calc(100% - 18px);"
                  @click="handleClick(stair)">
                <img class="icons" src="@/assets/img/file_list.png" alt="">
                <router-link :to="`/BMS/dept/emp/${stair.id}`" class="routerlinkyus"
                             style="width: calc(100% - 18px);">
                    <ellipsis-tooltip :text="stair.n || '-----'"></ellipsis-tooltip>
                </router-link>
            </span>
        </div>
    </div>
</template>

<script>
import EllipsisTooltip from '@/components/EllipsisTooltip.vue'//根据路径导入组件
import { sessionStorage, localStorage } from '@/utils/common/storage'
export default {
  name: 'Menus',
  props: {
    classify: Array,
    deptIds: Array,
    gaibland: String
  },
  components: {
    EllipsisTooltip
  },
  mounted(){
//    console.log(this.classify)
  },
  methods: {
    handleChange(val, stair){
      if (stair && stair.l) {
        localStorage.setItem("parent_name", stair.n)
        localStorage.setItem("menuLen", stair.l)
      }
      this.$emit("onChange", val)
    },
    handleClick(stair){
      if (stair && stair.l) {
        localStorage.setItem("parent_name", stair.n)
        localStorage.setItem("menuLen", stair.l)
      }
      this.$emit("onChange", stair.id + "")
    }
  }
}
</script>

<style>
    .searchselect {
        padding-top: 40px;
        width: 200px;
        height: 100%;
        border-right: 1px solid #eee;
    }

    .searchselect .classifysearch {
        width: 180px;
        margin-left: 10px;
    }

    .searchselect .el-input {
        font-size: 12px;
    }

    .searchselect .routerlinkyus {
        color: #08080A;
        position: relative;
    }

    .searchselect .routerlinkyus:after {
        content: " ";
        width: 40px;
        height: 40px;
        position: absolute;
        left: -40px;
        top: 0;

    }

    /* 折叠面板 */
    .searchselect .collapse {
        padding-right: 6px;
        max-height: 700px;
        overflow-x: scroll;
        overflow: overlay;
    }

    .searchselect .collapse .el-collapse {
        border-top: 0px !important;
    }

    /* slot放到左边 */
    .searchselect .collapse .collapse-title {
        display: flex;
        align-items: center;
        flex: 1 0 90%;
        order: 1;
        line-height: 40px;
    }

    .searchselect .collapse .el-collapse-item__header {
        flex: 1 0 auto;
        order: -1;
        font-size: 14px !important;
        background-color: #f9f9f9 !important;
        border-bottom: 0px !important;
        color: #8c8c8c;
        height: 40px;
        /* padding-left: 18px; */
        font-size: 18px;
        /* margin: 4px 6px 4px 6px; */

        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    /* 图标大小 */
    .searchselect .collapse .icons {
        width: 14px;
        height: 14px;
        margin-right: 4px;
    }

    .searchselect .collapse .el-collapse-item__arrow {
        margin: 0 4px 0 auto;
    }

    .searchselect .collapse .el-collapse-item__wrap {
        background-color: #f9f9f9 !important;
        border-bottom: 0px;
    }

    .searchselect .collapse .el-collapse-item__content {
        padding-bottom: 0px;
    }

    /* 一级列表 */
    .searchselect .collapse .stair {

    }

    /* 二级列表 */
    .collapse .second {
        display: flex;
        align-items: center;
        height: 40px;
        line-height: 40px;
        padding-left: 54px;
        text-align: left;
        color: #8c8c8c;
        font-size: 14px;
        /* 鼠标小手 */
        cursor: pointer;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

</style>