<template>
  <div class="one-table">
    <div class="top-container">
      <div class="top" layout="row" layout-align="start center">
        <icon-button
          @click.native="addOrUpdateHandle(1)"
          text="新增岗位"
          img="btn_add.png"
          colors="#383943"
        ></icon-button>
        <icon-button
          @click.native="addOrUpdateHandle(2)"
          text="编辑岗位"
          img="btn_edit.png"
          colors="#383943"
        ></icon-button>
        <icon-button
          @click.native="setEffectOrNotEffect(1)"
          text="置为无效"
          img="btn_in_vain.png"
          colors="#383943"
        ></icon-button>
        <icon-button
          @click.native="setEffectOrNotEffect(2)"
          text="置为有效"
          img="btn_effective.png"
          colors="#383943"
        ></icon-button>
        <icon-button
          @click.native="setEffectOrNotEffect(3)"
          text="批量删除"
          img="btn_delete.png"
          colors="#6B2830"
        ></icon-button>
        <characters-button
          @click.native="setConfigHandle(10)"
          colors="#383943"
          wz="角色权限"
        ></characters-button>
        <characters-button
          @click.native="openDistanceDialog"
          colors="#383943"
          wz="员工端距离限制"
        ></characters-button>
        <!-- <characters-button
          @click.native="setConfigHandle(1)"
          colors="#383943"
          wz="登录权限"
        ></characters-button> -->
        <characters-button
          @click.native="setConfigHandle(2)"
          colors="#383943"
          wz="可点区域"
        ></characters-button>
        <characters-button
          @click.native="setConfigHandle(3)"
          colors="#383943"
          wz="可点商品"
        ></characters-button>
        <characters-button
          @click.native="setConfigHandle(4)"
          colors="#383943"
          wz="优惠"
        ></characters-button>
        <characters-button
          @click.native="setConfigHandle(5)"
          colors="#383943"
          wz="优惠2"
        ></characters-button>
        <characters-button
          @click.native="setConfigHandle(6)"
          colors="#383943"
          wz="鸡尾酒关联商品"
        ></characters-button>
        <!-- <characters-button
          @click.native="setConfigHandle(7)"
          colors="#383943"
          wz="erp系统权限"
        ></characters-button> -->
        <!-- <characters-button
          @click.native="setConfigHandle(8)"
          colors="#383943"
          wz="配置权限"
        ></characters-button>
        <characters-button
          @click.native="setConfigHandle(9)"
          colors="#383943"
          wz="查单权限"
        ></characters-button> -->
        <characters-button
          @click.native="addOrUpdateHandle(3)"
          colors="#383943"
          wz="类似创建"
        ></characters-button>
       
      </div>
    </div>

    <div layout="row" layout-align="start center" style="margin:12px 0;">
      <el-input v-model="searchKey" placeholder="岗位名称"  clearable  style="width:200px" @change="getTableData"></el-input>
      <el-button type="primary" size="small" @click="getTableData" style="margin-left: 15px;">查询</el-button>
      <el-button type="info" @click.stop="restSearchData">重置</el-button>
    </div>
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">
              <el-checkbox
                v-model="checkAll"
                :indeterminate="isIndeterminate"
                @change="changeCheckboxHandle('all')"
                >全选</el-checkbox
              >
            </div>
            <div class="th">岗位名称</div>
            <div class="th">权限</div>
            <div class="th">岗位下员工数</div>
            <div class="th">状态</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">员工端距离限制</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{ selected: item.checked, gray: item.s == '无效' }"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">
              <div style="width: 60px; text-align: left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                  >{{ index + 1 }}</el-checkbox
                >
              </div>
            </div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.p }}</div>
            <div class="td">{{ item.ec }}</div>
            <div class="td">{{ item.s }}</div>
            <div class="td">{{ item.c }}</div>
            <div class="td">{{ item.u }}</div>
            <div class="td">{{ formatDistance(item.d) }}</div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <el-dialog
          title="员工端距离限制"
          :visible.sync="showDistanceDialog"
          width="480px"
          append-to-body
          :close-on-click-modal="false"
          :close-on-press-escape="!distanceSaving"
          :show-close="!distanceSaving"
        >
          <p>已选 {{ distanceStations.length }} 个岗位</p>
          <el-form label-width="100px" @submit.native.prevent="saveDistance">
            <el-form-item label="限制距离">
              <el-input v-model="distanceInput" @input="onDistanceInput" :disabled="distanceSaving" placeholder="0:不限制" inputmode="numeric">
                <template slot="append">米</template>
              </el-input>
            </el-form-item>
          </el-form>
          <p style="color: #909399; line-height: 1.6">请输入 0 或大于 0 的整数（单位：米），0 表示不限制。</p>
          <span slot="footer">
            <el-button :disabled="distanceSaving" @click="showDistanceDialog = false">取消</el-button>
            <el-button type="primary" :loading="distanceSaving" @click="saveDistance">确定</el-button>
          </span>
        </el-dialog>
        <!-- 新增或编辑 -->
        <drawerAddOrUpdateStation
          v-model="showAddOrUpdateDrawer"
          :currentInfo="currentInfo"
          :type="type"
          @getTableData="getTableData"
        />
        <!-- 置为有效无效删除冲突 -->
        <drawerNextDrawer
          v-model="showNextDrawer"
          :effectType="effectType"
          :nexDrawerInfo="nexDrawerInfo"
          @getTableData="getTableData"
          @setEffectOrNotEffect="setEffectOrNotEffect"
        />
        <!-- 登录权限 -->
        <drawerLoginConfig
          v-model="showLoginDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 可点区域 -->
        <drawerCanOrderArea
          v-model="showCanOrderAreaDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 可点商品 -->
        <drawerCanOrderPrd
          v-model="showCanOrderPrdDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 优惠/优惠2 -->
        <drawerCanYHPrd
          v-model="showCanYHPrdDrawer"
          :type="yhType"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 鸡尾酒 -->
        <drawerTYPrd
          v-model="showTYPrdDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- erp管理 -->
        <drawerErpConfig
          v-model="showErpDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 配置权限 -->
        <drawerSetConfig
          v-model="showSetConfigDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 查单权限 -->
        <drawerLookOrder
          v-model="showLookOrderDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
        <!-- 角色权限 -->
        <drawerRoleAuth
          v-model="showRoleAuthDrawer"
          :checkedList="checkedList"
          @getTableData="getTableData"
        />
    

      </div>
    </div>
  </div>
</template>

<script>
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import drawerAddOrUpdateStation from "./stationConfigCom/drawerAddOrUpdateStation.vue";
import drawerNextDrawer from "./stationConfigCom/drawerNextDrawer.vue";
export default {
  data() {
    return {
      showDistanceDialog: false,
      distanceStations: [],
      distanceInput: "",
      distanceSaving: false,
      searchKey: "", // 搜索关键字
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1无效  2有效 3删除
      dragInfo: {}, // 拖拽信息
      currentInfo: {}, // 当前修改的数据
      showAddOrUpdateDrawer: false,
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      showLoginDrawer: false, // 登录权限
      showCanOrderAreaDrawer: false, // 可点区域
      showCanOrderPrdDrawer: false, // 可点商品
      showCanYHPrdDrawer: false, // 优惠/优惠2
      showTYPrdDrawer: false, // 鸡尾酒
      showErpDrawer: false, // erp管理
      showSetConfigDrawer: false, // 配置权限
      showLookOrderDrawer: false, // 查单权限
      showRoleAuthDrawer: false, // 角色权限
      nexDrawerInfo: {
        ns: [],
        cs: [],
      },

      checkedList: [], // 当前所选择的岗位数据数组信息
      yhType: 1, // 1：优惠  2：优惠2
    };
  },
  methods: {
    formatDistance(value) {
      return Number(value) > 0 ? value + "米" : "不限制";
    },
    openDistanceDialog() {
      if (this.distanceSaving) return;
      const selected = this.tableData.filter(item => item.checked);
      if (!selected.length) return this.$message.warning("请选择岗位");
      this.distanceStations = selected.map(item => ({ id: item.id }));
      this.distanceInput = "";
      this.showDistanceDialog = true;
    },
    onDistanceInput(value) {
      this.distanceInput = String(value).match(/^\d*/)[0];
    },
    async saveDistance() {
      if (this.distanceSaving) return;
      const input = String(this.distanceInput).trim();
      const distance = Number(input);
      if (!/^\d+$/.test(input) || !Number.isSafeInteger(distance) || distance < 0) {
        return this.$message.warning("请输入非负整数距离，0 表示不限制");
      }
      if (!this.distanceStations.length) return this.$message.warning("请选择岗位");
      this.distanceSaving = true;
      try {
        const res = await this.$api.BMS.station.requestStationSetDistance({
          station_ids: this.distanceStations.map(item => item.id),
          distance,
        });
        if (res.code == 1) {
          this.showDistanceDialog = false;
          this.$message.success("设置成功");
          this.getTableData();
        } else {
          this.$message.warning(res.msg || "设置失败，请重试");
        }
      } catch (error) {
        this.$message.warning("设置失败，请重试");
      } finally {
        this.distanceSaving = false;
      }
    },
    async getTableData() {
      const checked = this.tableData.filter((item) => item.checked);

      console.log('checkedNow:', checked)
      try {
        const params = {
          key: this.searchKey,
        };
        const res = await this.$api.BMS.station.requestStationList(params);
        if (res.code == 1) {
          this.tableData = (res.data || []).map((item) => ({
            ...item,
            checked: checked && checked.length? checked.some((a) => a.id === item.id): false
          }));
          this.checkAll = false;
          this.$emit("getMenuList");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    // 新增或修改
    addOrUpdateHandle(type) {
      const checkedList = this.tableData.filter((item) => item.checked);
      if (type == 2 || type == 3) {
        if (checkedList.length == 1) {
          this.currentInfo = checkedList[0];
        } else {
          return this.$message.warning("请选择一条数据进行操作");
        }
      }
      this.showAddOrUpdateDrawer = true;
      this.type = type;
    },

    // 设为有效或无效或删除
    async setEffectOrNotEffect(type) {
      // type : 1无效  2有效 3删除
      this.effectType = type;
      const checkedList = this.tableData.filter((item) => item.checked);
      if (checkedList.length <= 0)
        return this.$message.warning("请选择一个进行操作");
      const params = {
        ids: checkedList.map((item) => item.id * 1),
      };
      try {
        const api =
          type == 1
            ? "requestStationDisable"
            : type == 2
            ? "requestStationEnable"
            : "requestStationDel";
        const res = await this.$api.BMS.station[api](params);
        if (res.code == 1) {
          this.getTableData();
          this.$message.success("操作成功");
        } else if (res.code == 2) {
          this.showNextDrawer = true;
          this.nexDrawerInfo.ns = res.data.ns || [];
          this.nexDrawerInfo.cs = (res.data.cs || []).map((item) => ({
            ...item,
            jg: "---",
          }));
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("设置有效无效失败", error);
      }
    },

    // 设置权限
    setConfigHandle(type) {
      const checkedList = this.tableData.filter((item) => item.checked);
      if (checkedList.length <= 0) return this.$message.warning("请选择岗位");
      this.checkedList = [...checkedList];
      switch (type) {
        case 1:
          // 登录权限
          this.showLoginDrawer = true;
          break;
        case 2:
          // 可点区域
          this.showCanOrderAreaDrawer = true;
          break;
        case 3:
          // 可点商品
          this.showCanOrderPrdDrawer = true;
          break;
        case 4: // 优惠
        case 5: // 优惠2
          if (checkedList.length != 1)
            return this.$message.warning("请选择一个岗位进行配置");
          this.yhType = type == 4 ? 1 : 2;
          this.showCanYHPrdDrawer = true;
          break;
        case 6:
        if (checkedList.length != 1)
            return this.$message.warning("请选择一个岗位进行配置");
          // 鸡尾酒关联商品
          this.showTYPrdDrawer = true;
          break;
        case 7:
          // erp系统权限
          this.showErpDrawer = true;
          break;
        case 8:
          // 配置权限
          this.showSetConfigDrawer = true;
          break;
        case 9:
          // 查单权限
          this.showLookOrderDrawer = true;
          break;
        case 10:
          // 角色权限
          this.showRoleAuthDrawer = true;
          break;
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map((item) => ({
            ...item,
            checked: this.checkAll,
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every((item) => item.checked);
          break;
      }
    },
      // 重置
      restSearchData() {
        this.searchKey = ""
        this.getTableData();
      },
  },
  created() {
    this.getTableData();
  },
  mounted() {},
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some((item) => item.checked);
    },
  },
  components: {
    CharactersButton,
    IconButton,
    drawerAddOrUpdateStation,
    drawerNextDrawer,
    drawerLoginConfig: () => import("./stationConfigCom/drawerLoginConfig.vue"),
    drawerCanOrderArea: () =>
      import("./stationConfigCom/drawerCanOrderArea.vue"),
    drawerCanOrderPrd: () => import("./stationConfigCom/drawerCanOrderPrd.vue"),
    drawerCanYHPrd: () => import("./stationConfigCom/drawerCanYHPrd.vue"),
    drawerTYPrd: () => import("./stationConfigCom/drawerCanTYPrd.vue"),
    drawerErpConfig: () => import("./stationConfigCom/drawerErpConfig.vue"),
    drawerSetConfig: () => import("./stationConfigCom/drawerSetConfig.vue"),
    drawerLookOrder: () => import("./stationConfigCom/drawerLookOrder.vue"),
    drawerRoleAuth:() => import("./stationConfigCom/drawerRoleAuth.vue"),
  },
  watch: {
    $route: {
      handler() {
        this.getTableData();
      },
    },
  },
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.one-table {
  padding: 20px;
  position: relative;
  
  .top-container {
    position: sticky;
    top: 0;
    z-index: 100;
    background-color: #fff;
    padding-bottom: 12px;
  }
  
  .top {
    background-color: #eee;
    flex-wrap: wrap;
  }
  
  .table-content {
    .table {
      max-height: calc(100vh - 200px);
      overflow: auto;
      .th,
      .td {
        &:nth-child(1),
        &:nth-child(5) {
          width: 30%;
        }
        &:nth-child(3) {
          width: 80%;
        }
        &:nth-child(4) {
          width: 40%;
        }
      }
    }
  }
}
</style>
