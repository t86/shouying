<template>
  <div class="report-TY p-5 fs14">
    <div class="red-color tips" >说明：请勾选需要单独统计的部门，加入sheet列表，勾选父级部门，子部门默认统计到父级；如子部门需要单独统计，可直接勾选子部门；没有配置的部门将统计到系统默认的“其他”sheet表中</div>
    <div class="config" layout="row" layout-align="space-between start">
      <div class="left">
        <treeCom :list="treeData" @change="changeCheckBoxHandle" />
      </div>
      <div class="center">
        <el-button style="margin-top:100px" type="primary" size="small" @click="addHandle">加入sheet列表>></el-button>
      </div>
      <div class="right">
        <div class="table-content">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">序号</div>
                <div class="th">sheet名称</div>
                <div class="th">操作</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData" :key="item.id">
                <div class="td">{{index + 1}}</div>
                <div class="td">{{item.n}}</div>
                <div class="td">
                  <span class="cursor primary-link" @click="deleteHandle(item)">删除</span>
                </div>
              </div>
              <div class="no-data" v-if="tableData.length==0">
                <img :src="require('@/assets/img/wu.png')" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import eventVue from '@/utils/eventVue';
export default {
  data() {
    return {
      index: 0,
      treeData: [],
      tableData: [],
      checkedIdList: [],  // 提交时所获取的选中的树形结构id
    };
  },
  methods: {
    async getTreeData() {
      try {
        const res = await this.$api.BMS.reportConfig.reqGetTYTreeData();
        if (res.code == 1) {
          this.treeData = res.data.depts || [];
          this.setAttr(this.treeData)
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    changeCheckBoxHandle({ event, itemInfo }) {
      const treeData = [...this.treeData]
      this.setAttr(treeData, itemInfo, event)
      this.treeData = [...treeData]
    },

    // 递归处理树形结构数据
    setAttr(arr = [], itemInfo = {}, checked = false, disabled = false) {
      arr.forEach(el => {
        el.key = this.$overall.generateUUID()
        // el.disabled = (disabled && el.id != itemInfo.id) || (!el.checked && itemInfo.checked && el.id == itemInfo.pid) || false;
        el.disabled = !!this.tableData.find(item => item.id == el.id)
        el.checked = el.id == itemInfo.id ? checked : el.checked;
        el.subs = el.subs || [];
        if (el.subs.length > 0) this.setAttr(el.subs, itemInfo, checked, el.checked || el.disabled);
      });
    },

    // 递归获取选中的id
    getCheckedId(arr = []) {
      arr.forEach(el => {
        if(el.checked) this.checkedIdList.push(el.id)
        if (el.subs.length > 0) this.getCheckedId(el.subs);
      });
    },

    // 向表格添加数据
    async addHandle(){
      this.checkedIdList = []
      this.getCheckedId(this.treeData)
      const params = {
        dept_ids: this.checkedIdList, //   []int64      //DeptIds 待添加的部门列表
      }
      try {
        const res = await this.$api.BMS.reportConfig.reqAddTYTreeData(params)
        if(res.code == 1) {
          this.$message.success('添加成功')
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    // 获取表格数据
    async getTableData(){
      try {
        const res = await this.$api.BMS.reportConfig.reqGetConfig()
        if(res.code == 1) {
          this.tableData = res.data.records || []
          this.getTreeData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    // 删除表格数据
    async deleteHandle(itemInfo){
      const params = {
        dept_id: itemInfo.id * 1, //    int64    部门Id
      }
      try {
        const res = await this.$api.BMS.reportConfig.reqDelTYTreeData(params)
        if(res.code == 1) {
          this.getTableData()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    }
  },
  created() {
    this.getTableData()
  },
  mounted() {
    eventVue.$on('changeTreeItem', this.changeCheckBoxHandle)
  },
  beforeDestroy() {
    eventVue.$off('changeTreeItem')
  },
  props: {},
  components: {},
  filters: {}
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.report-TY {
  height: calc(100vh - 110px);
  overflow: auto;
  .tips {
    line-height: 26px;
  }
  .left {
    width: 30%;
    max-height: calc(100vh - 180px);
    overflow: auto;
  }
  .right {
    width: 50%;
    .table-content {
      border: 1px solid #f9f9f9;
      max-height: calc(100vh - 180px);
      overflow: auto;
    }
  }
  .center {
    width: 20%;
  }
}
</style>