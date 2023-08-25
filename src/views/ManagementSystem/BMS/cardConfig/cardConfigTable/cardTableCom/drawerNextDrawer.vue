<template>
  <div>
    <!-- 有效无效删除冲突 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div v-if="cs.length > 0">
          <span>以下对象存在依赖，需人工处理依赖</span>
          <el-button type size="mini" @click.native="asyncDoHandle">同步处理</el-button>
          <div class="table-content m-t-3">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">说明</div>
                  <div class="th">处理结果</div>
                </div>
              </div>
              <div class="tbody">
                <div
                  class="tr"
                  v-for="(item,i) in cs || []"
                  :key="i"
                  layout="row"
                  layout-align="space-between center"
                >
                  <div class="td">{{i+1}}</div>
                  <div class="td">{{item.r}}</div>
                  <div class="td">
                    <span v-if="item.jg == '成功'" style="color: #00BC72;">{{item.jg}}</span>
                    <span v-if="item.jg == '---'" >{{item.jg}}</span>
                    <span v-if="item.jg == '失败'" style="color: #E13B50;">{{item.jg}}</span>
                  </div>
                </div>
                <div class="no-data" v-if="(cs || []).length==0">
                  <img :src="require('@/assets/img/wu.png')" alt />
                  <p>暂无数据</p>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div v-if="nexDrawerInfo.ns.length > 0" >
          <span>以下对象存在依赖，需人工处理依赖</span>
          <div class="table-content m-t-3">
            <div class="table">
              <div class="thead">
                <div class="tr" layout="row" layout-align="space-between center">
                  <div class="th">序号</div>
                  <div class="th">说明</div>
                </div>
              </div>
              <div class="tbody">
                <div
                  class="tr"
                  v-for="(item,i) in nexDrawerInfo.ns || []"
                  :key="i"
                  layout="row"
                  layout-align="space-between center"
                >
                  <div class="td">{{i+1}}</div>
                  <div class="td">{{item}}</div>
                </div>
                <div class="no-data" v-if="(nexDrawerInfo.ns || []).length==0">
                  <img :src="require('@/assets/img/wu.png')" alt />
                  <p>暂无数据</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      cs: []
    };
  },
  methods: {
    async asyncDoHandle(){
      const params = {
        op_status: this.effectType == 1 ? 2 : (this.effectType == 2 ? 1 : 3),
        type_ids: this.nexDrawerInfo.cs.map(item => item.tid),
        ids: this.nexDrawerInfo.cs.map(item => item.id)
      }
      try {
        const res = await this.$api.BMS.seat.requestSeatOb(params)
        if(res.code == 1) {
          this.cs = this.cs.map(item => ({
            ...item,
            jg : '成功'
          }))
          this.onCancelDrawer()
          this.$emit('setEffectOrNotEffect', this.effectType)
          this.$emit('getTableData')
        } else if(res.code == 2) {
         for (const key in this.cs) {
            for (const keys in res.data) {
              if (this.cs[key].id == res.data[keys].id) {
                this.cs[key].jg = '失败'
              }
            }
          }
          for (const key in this.cs) {
            if (this.cs[key].jg == '---') {
              this.cs[key].jg = '成功'
            }
          }
          this.$forceUpdate()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('同步处理失败', error);
      }
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
    effectType: {
      default: 1  // 1无效  2有效 3删除
    },
    nexDrawerInfo: {
      default: () => ({})
    }
  },
  computed: {
    title() {
      return this.effectType == 1 ? "置为无效" : this.effectType == 2 ? "置为有效" : "批量删除";
    },

    show: {
      get() {
        return this.value;
      },

      set(val) {
        this.$emit("input", val);
      }
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.cs = this.nexDrawerInfo.cs || []
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.table {
  .th,.td {
    &:nth-child(2) {
      width: 80%;
    }
  }
}
</style>