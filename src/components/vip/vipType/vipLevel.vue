<template>
  <div>
    <div>
      <label for="autoUpgrade">卡等级自动升级:</label>
      <input type="checkbox" id="autoUpgrade" v-model="autoUpgradeEnabled">
      <div style="padding-left:30px; font-size: 14px;color: gray; margin: 10px 5px;">开关开启后需配置每个等级的等级经验门槛值，达到后，客人端将自动升级</div>
    </div>
    <!-- <div v-if="autoUpgradeEnabled">
      <h3>卡等级所需经验值:</h3>
      <div class="table">
        <div class="thead" >
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">等级</div>
            <div class="th">需要的经验值</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(level, index) in levels" :key="index">
            <div class="td">{{ level.name }}</div>
            <div class="td">
              <input type="number" v-model="level.experienceThreshold">
            </div>
          </div>
        </div>
      </div>
    </div> -->
    <div class="top" layout="row" layout-align="start center">
      <icon-button
        @click.native="addLevel()"
        text="新增"
        img="btn_add.png"
        bjcolors="#DDE0E9"
        bcolor="#8c8c8c"
      ></icon-button>
    </div>

    <div class="table">
      <div class="thead" >
        <div class="tr" layout="row" layout-align="space-between center">
          <div class="th">等级名称</div>
          <div class="th">等级封面</div>
          <div class="th" v-if="autoUpgradeEnabled">等级经验值（达到该值后自动升级）</div>
          <div class="th">操作</div>
        </div>
      </div>
      <div class="tbody">
        <div class="tr" layout="row" layout-align="space-between center" v-for="(level, index) in levels" :key="index">
          <div class="td">{{ level.name }}</div>
          <div class="td">
            <img :src="level.cover" alt="等级封面" width="100" height="100">
          </div>
          <div class="td" v-if="autoUpgradeEnabled">
            {{ level.experienceThreshold }}
            <!-- <el-input v-model="level.experienceThreshold" :type="inputType" :placeholder="请输入经验门槛值"></el-input> -->
          </div>
          <div class="td">
            <div layout="row" layout-align="start center">
              <icon-button
              @click.native="editLevel(index)"
              text="编辑"
              img="btn_edit.png"
              bjcolors="#DDE0E9"
              bcolor="#8c8c8c"
            ></icon-button>
            <icon-button @click.native="deleteLevel(index)"
            text="批量删除" img="btn_delete.png" colors="#6B2830">
            </icon-button>
            </div>
          </div>
        </div>
      </div>
    </div>
    <drawerLevel
      :isDefault="isDefault"
      :showDrawer="showDrawer"
    />
  </div>
</template>

<script>
import IconButton from "@/components/IconButton.vue";
import drawerLevel from "./drawerLevel.vue"
export default {
  data() {
    return {
      autoUpgradeEnabled: false,
      levels: [
      ],
      isDefault: true,
      showDrawer: false,
    };
  },
  methods: {
    addLevel() {
      this.showDrawer = true
    },
    editLevel(index) {

    },
    deleteLevel(index) {
      this.levels.splice(index, 1);
    },
  },
  components: {
    IconButton,
    drawerLevel
  },
};
</script>

<style lang="less"  scoped>
@import "../../../style/common/elementDrawerVip.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/vip/vip.less";
@import "../../../style/vip/vipPagination.less";

.table {
    overflow-y: auto;
    .tr {
      .th,
      .td {
        width: 30%;
      }
      .th:nth-child(1),
      .td:nth-child(1),
      .th:nth-last-child(1),
      .td:nth-last-child(1) {
        width: 20%;
        span{
          color: #2362D5;
          cursor: pointer;
        }
      }
    }
  }
</style>
