<template>
  <div>
    <!-- 修改存酒入库单 -->
    <el-drawer
      title="编辑"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="800px"
    >
      <div class="session edit-save-info p-5">
        <div class="top" layout="row" layout-align="start center">
          <div class="title">充公详情</div>
          <div class="time">充公时间：{{currentWineInfo.t}}</div>
          <div class="person-info">订位人：{{currentWineInfo.e}}</div>
        </div>
        <div class="red m-t-3 m-b-3">点击规格可更改</div>
        <!-- 表格 -->
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">名称</div>
                <div class="th">规格</div>
                <div class="th">每瓶克数</div>
                <div class="th">数量</div>
                <div class="th" style="width:120px">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="item in tableData"
                :key="item.id"
              >
                <div class="td">{{item.n}}</div>
                <div class="td">
                  <div v-if="item.u == '整瓶'">{{item.u}}</div>
                  <div v-else>
                    <el-select v-model="item.u" size="mini" style="width:100px" placeholder="请选择">
                      <el-option
                        v-for="item in options"
                        :key="item.value"
                        :label="item.label"
                        :value="item.label"
                      ></el-option>
                    </el-select>
                  </div>
                </div>
                <div class="td">
                  <div v-if="item.u == '整瓶'">{{item.g || '-'}}</div>
                  <div v-else>
                    <el-input v-model="item.g" size="mini" style="width:100px"></el-input>
                  </div>
                </div>
                <div class="td" layout="row" layout-align="center center">
                  <el-button
                    type
                    size="small"
                    style="width:26px;padding:0;height:26px;border-radius:50%"
                    icon="el-icon-minus"
                    :disabled="item.c<=1"
                    @click="item.c = Math.max(1, item.c - 1)"
                  ></el-button>
                  <el-input v-model="item.c" size="mini" style="width:60px;margin:0 10px"></el-input>
                  <el-button
                    type
                    size="mini"
                    style="width:26px;padding:0;height:26px;border-radius:50%"
                    icon="el-icon-plus"
                    @click="item.c++"
                  ></el-button>
                </div>
                <div class="td" style="width:120px"><span style="color:#2170ff;cursor:pointer" @click="deleteHandle(item)">删除</span></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 授权 -->
      <authCom
        ref="authRef"
        v-model="showAuthDrawer"
        :tableData="tableData"
        @emitHandle="onSubmit"
      />

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确认修改</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import authCom from "../commonCom/auth.vue";
export default {
  data() {
    return {
      tableData: [],
      showAuthDrawer: false,
      options: [
        { id: 1, label: "0.1" },
        { id: 2, label: "0.2" },
        { id: 3, label: "0.3" },
        { id: 4, label: "0.4" },
        { id: 5, label: "0.5" },
        { id: 6, label: "0.6" },
        { id: 7, label: "0.7" },
        { id: 8, label: "0.8" },
        { id: 9, label: "0.9" }
      ]
    };
  },
  methods: {
    async onSubmit({ userName, passWord, type }) {
      const params = {
        bef_cg_id: this.currentWineInfo.o * 1, //  int64      //BefInId 待入库订单Id
        bef_cg_dtl_ids: this.tableData.map(item => item.id * 1), //  []int64   待入库子订单Id
        unit_types: this.tableData.map(item =>
          item.u == "整瓶" ? "1" : item.u
        ), //  []string   对应子定单修改后的规格
        prd_cnts: this.tableData.map(item => item.c * 1), //   []int   对应子订单修改后的商品数量
        g_cnts: this.tableData.map(item => item.g * 1), //     []int        //GCnts 对应子订单修改后的克数
      };
      try {
        const res = await api_wine.reqChgCsmCgBefIn(params);
        if (res.code == 1) {
          this.$message.success("修改成功");
          this.showAuthDrawer = false;
          this.onCancelDrawer();
          this.$emit("getTableData");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("授权修改存酒充公信息失败", error);
      }
    },

    deleteHandle(itemInfo){
      const index = this.tableData.findIndex(item => item.id == itemInfo.id)
      if(index > -1) {
        this.tableData.splice(index, 1)
      }
    },

    showAuthHandle(){
      if(this.tableData.length <= 0) return this.$message.warning('当前暂无商品可授权')
      this.showAuthDrawer = true
    },

    onCancelDrawer() {
      this.show = false;
    }
  },
  mounted() {},
  props: {
    value: {
      default: false // 是否显示drawer
    },
    currentWineInfo: {
      default: () => ({})
    }
  },
  computed: {
    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  components: {
    authCom
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.tableData = JSON.parse(
            JSON.stringify(this.currentWineInfo.ss || [])
          );
        } else {
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerWine.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/common/elementFormBtnWine.less";
@import "../../../../style/wine/table.less";
</style>

<style lang="less" scoped>
.edit-save-info {
  .top {
    .title {
      font-size: 20px;
      font-weight: 600;
    }
    .time {
      margin: 0 30px;
    }
  }
  .red {
    color: #f56c6c;
  }

  .table {
    .tbody {
      max-height: calc(100vh - 270px);
      overflow: auto;
    }
  }
}
</style>