<template>
  <div class="one-table">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="addOrUpdateHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="addOrUpdateHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="deleteHandle" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <icon-button @click.native="handleStatus('disable')" text="停用" img="btn_disable.png" colors="#6B2830"></icon-button>
      <icon-button @click.native="handleStatus('enable')" text="启用" img="btn_enable.png" colors="#383943"></icon-button>
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
            :class="{'selected': item.checked, 'gray': item.s === '停用'}"
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
        <!-- 添加确认框 -->
        <el-dialog
          :title="dialogType === 'disable' ? '停用' : '启用'"
          :visible.sync="showConfirmDialog"
          width="400px"
          :close-on-click-modal="false"
          :close-on-press-escape="false"
        >
          <div class="dialog-content">
            <p v-if="dialogType === 'disable'">确定停用所选商品组? 停用后，员工无法赠送该商品组的商品！</p>
            <p v-else>确定启用所选商品组? 启用后，员工可赠送该商品组的商品！</p>
          </div>
          <span slot="footer" class="dialog-footer">
            <el-button @click="showConfirmDialog = false">取消</el-button>
            <el-button type="primary" @click="confirmStatusChange">确定</el-button>
          </span>
        </el-dialog>
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
      },
      showConfirmDialog: false, // 控制确认框显示
      dialogType: '', // 'disable' 或 'enable'
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

    handleStatus(type) {
      const checkedList = this.tableData.filter(item => item.checked)
      if(checkedList.length <= 0) {
        return this.$message.warning('请选择要操作的数据')
      }

      this.dialogType = type
      this.showConfirmDialog = true
    },

    async confirmStatusChange() {
      const checkedList = this.tableData.filter(item => item.checked)
      const params = {
        ids: checkedList.map(item => item.id * 1)
      }

      try {
        let res
        if(this.dialogType === 'disable') {
          res = await this.$api.BMS.pgrp.pgrd_disable(params)
        } else {
          res = await this.$api.BMS.pgrp.pgrd_enable(params)
        }

        if(res.code == 1) {
          this.$message.success('操作成功')
          this.getTableData() // 刷新表格数据
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log(`${this.dialogType === 'disable' ? '停用' : '启用'}操作失败`, error)
        this.$message.error(`${this.dialogType === 'disable' ? '停用' : '启用'}操作失败`)
      } finally {
        this.showConfirmDialog = false
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
      
      .tr.gray {
        background-color: #f5f5f5;
        color: #999;
      }
    }
  }
}

.dialog-content {
  padding: 20px 0;
  p {
    margin: 0;
    line-height: 1.5;
  }
}

/deep/ .el-dialog__header {
  padding: 15px 20px;
  border-bottom: 1px solid #eee;
}

/deep/ .el-dialog__body {
  padding: 0 20px;
}

/deep/ .el-dialog__footer {
  padding: 15px 20px;
  border-top: 1px solid #eee;
}
</style>