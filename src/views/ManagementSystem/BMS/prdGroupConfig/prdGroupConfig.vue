<template>
  <div class="one-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateHandle(1)" text="新增" img="添加.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateHandle(2)" text="编辑" img="编辑.png" colors="#383943"></icon-button>
      <icon-button @click.native="deleteHandle" text="批量删除" img="删除.png" colors="#6B2830"></icon-button>
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
              >全选</el-checkbox>
            </div>
            <div class="th">商品组名称</div>
            <div class="th">二级分类数量</div>
            <div class="th">商品数量</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
            <div class="th">状态</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">
              <div style="width: 60px;text-align:left">
                <el-checkbox
                  v-model="item.checked"
                  @change="changeCheckboxHandle('item')"
                >{{index + 1}}</el-checkbox>
              </div>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.cc}}</div>
            <div class="td">{{item.pc}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.s}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <!-- 新增或编辑 -->
        <drawerAddOrUpdatePrdGroup v-model="showDrawer" :currentInfo="currentInfo" :type="type" @getTableData="getTableData" />
        <!-- 置为删除冲突 -->
        <drawerNextDrawer v-model="showNextDrawer" :nexDrawerInfo="nexDrawerInfo"  @getTableData="getTableData" @setEffectOrNotEffect="deleteHandle" />
      </div>
    </div>
  </div>
</template>
 
<script>
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      tableData: [],
      checkAll: false,
      type: 1, // 1:新增  2：修改
      effectType: 1, // 1无效  2有效 3删除
      currentInfo: {}, // 当前修改的数据
      showDrawer: false,
      showNextDrawer: false, // 有效无效删除冲突时的下一步操作drawer
      nexDrawerInfo: {
        ns: [],
        cs: []
      }
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.pgrp.requestpgrplist()
        if (res.code == 1) {
          this.tableData = (res.data || []).map(item => ({
            ...item,
            checked: false
          }));
          this.checkAll = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    // 新增或修改
    addOrUpdateHandle(type) {
      const checkedList = this.tableData.filter(item => item.checked)
      if(type == 2) {
        if(checkedList.length == 1) {
          this.currentInfo = checkedList[0]
        } else {
          return this.$message.warning('请选择一条数据进行操作')
        }
      }
      this.showDrawer = true
      this.type = type
    },

    // 删除
    async deleteHandle(){
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) return this.$message.warning('请选择')
      const params = {
        ids: checkedList.map(item => item.id * 1)
      }
      try {
        const res = await this.$api.BMS.pgrp.requestpgrpdel(params)
        if(res.code == 1) {
          this.getTableData()
          this.$message.success('操作成功')
        } else if(res.code == 2) {
          this.showNextDrawer = true
          this.nexDrawerInfo.ns = res.data.ns || []
          this.nexDrawerInfo.cs = (res.data.cs || []).map(item => ({
            ...item,
            jg: '---'
          }))
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('删除失败', error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
        case "all":
          this.tableData = this.tableData.map(item => ({
            ...item,
            checked: this.checkAll
          }));
          break;
        case "item":
          this.checkAll = this.tableData.every(item => item.checked);
          break;
      }
    },

  },
  created() {
    this.getTableData();
  },
  mounted() {},
  computed: {
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked);
    }
  },
  components: {
    CharactersButton,
    IconButton,
    drawerAddOrUpdatePrdGroup: () => import('./prdGroupCom/drawerAddOrUpdatePrdGroup.vue'),
    drawerNextDrawer: () => import('./prdGroupCom/drawerNextDrawer.vue')
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.one-table {
  padding: 20px;
  .top {
    background-color: #eee;
  }
  .table-content {
    .table {
      max-height: calc(100vh - 160px);
      overflow: auto;
      .th,.td{
        &:nth-child(1),
        &:nth-child(3),
        &:nth-child(4),
        &:nth-child(7){
          width: 30%;
        }
      }
    }
  }
}
</style>