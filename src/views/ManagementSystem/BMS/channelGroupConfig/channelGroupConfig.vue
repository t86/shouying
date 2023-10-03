<template>
  <div class="sta-container">
    <div class="top" layout="row" layout-align="start center">
      <p class="red">说明：请重新划分商品分类，在收银系统将根据新配置的统计类别汇总各渠道类别收入</p>
    </div>

    <div class="m-t-3">
      <el-button type="primary" size="small" @click="showOrHideDrawerHandle(1)">新增类别</el-button>
      <el-button type="primary" size="small" @click="showOrHideDrawerHandle(2)">编辑</el-button>
      <el-button size="small" type="primary" @click="deleteHandle">批量删除</el-button>
      <el-button size="small" type="primary" @click.native="$message.info('上下拖动商品可调整顺序')">调整顺序</el-button>
    </div>

    <!-- table -->
    <div class="table-content m-t-2"> 
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox
                v-model="checked"
                :indeterminate="indeterminate"
                @change="changeCheckboxHandle('all')"
              >序号</el-checkbox>
            </div>
            <div class="th">渠道类别名称</div>
            <div class="th">包含渠道</div>
            <div class="th">创建时间</div>
            <div class="th">更新时间</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            :class="{'selected': item.checked,'gray': item.s == '无效'}"
            v-for="(item,index) in tableData"
            :key="index"
            layout="row"
            layout-align="start center"
            :draggable="true"
            @dragstart="dragstart(item)"
            @dragenter="dragenter(item)"
            @dragend="dragend(item)"
            title="拖动可调整顺序"
          >
            <div class="td">
              <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{index+1}}</el-checkbox>
            </div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.cs}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.u}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <drawerAddPrdCom
      :showDrawer="showDrawer"
      :item="currentInfo"
      @showOrHideDrawerHandle="showOrHideDrawerHandle"
      @getTableData="getTableData"
    />
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      oldItem: {}, // 拖拽初始信息
      newItem: {}, // 拖拽过程中信息
      keyword: '',
      checked: false,
      indeterminate: false,
      tableData: [],
      showDrawer: false,
      currentInfo: {}
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.channelConfig.reqDelPrdConfig()
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false
          }));
          this.indeterminate = this.checked = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },
    changeCheckboxHandle(type){
      switch(type) {
        case "all":
          this.tableData.forEach(el => {
            el.checked = this.checked;
          });
          this.indeterminate = false;
          break;
        case "item":
          this.checked = this.tableData.every(item => item.checked);
          this.indeterminate =
            !this.checked && this.tableData.some(item => item.checked);
          break;
      }
    },
    async deleteHandle(){
      const params = {
            ids: this.tableData.filter(item => item.checked).map(item => item.id * 1), //        []int64      //PrdIds 待添加的商品Id列表
          }
      if(params.ids.length <= 0) return this.$message.warning('请选择需要删除的商品')
      this.$confirm('是否确认删除？', '批量删除', {
          distinguishCancelAndClose: true,
          confirmButtonText: '确定',
          cancelButtonText: '取消'
        }).then(async () => {
          try {
            const res = await this.$api.BMS.miniProgressConfig.reqDelMiniData(params)
            if(res.code == 1) {
              this.$message.success('删除成功')
              this.getTableData()
            } else {
              this.$message.warning(res.msg)
            }
          } catch (error) {
            console.log('数据请求失败', error);
          }
        }).catch(e => '')

    
    },

    showOrHideDrawerHandle(isNew = 1){
      if(isNew != 1) {
        if(this.tableData.filter(item => item.checked).length != 1){
          this.$message.warning("请选择且仅选择一个渠道类别")
          return 
        }
      }
      this.currentInfo = this.tableData.find(item => item.checked)
      this.showDrawer = !this.showDrawer

    },
    resetHandle(){
      this.keyword = ''
      this.getTableData()
    },
     // 记录初始信息
     dragstart(item) {
      this.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.newItem = item;
    },
    // 做最终操作
    async dragend(item) {
      if (this.oldItem != this.newItem) {
        let oldIndex = this.tableData.indexOf(this.oldItem);
        let newIndex = this.tableData.indexOf(this.newItem);
        let down_up = 1;
        if (oldIndex > newIndex) {
          down_up = 2
        } else if (oldIndex < newIndex) {
          down_up = 1
        }

        const params = {
          id: this.oldItem.id,
          dest_id: this.newItem.id,
          down_up: down_up
        }
        try {
          const res = await this.$api.BMS.channelConfig.reqGetPrdCateList(params)
          if(res.code == 1) {
            this.$message.success("更改位置成功")
            let newList = [...this.tableData]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.oldItem);
            // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          
        }
      }
    },
  },
  created() {
    this.resetHandle();
  },
  components: {
    drawerAddPrdCom: () => import('./drawerAddChannelCom/drawerAddChannelCom.vue')
  },
  filters: {},
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.sta-container {
  padding: 20px;

  /* 取消按钮 */
.el-message-box__btns .el-button--default{
    background-color: #2170ff !important;
    border: 1px solid #7298FF !important;
    color: red !important;
}
.el-message-box__btns .el-button--default:hover{
    background-color: #1664f5 !important;
    border: 1px solid #6788e2 !important;
}  

  .red {
    color: red;
  }

  .table {
    max-height: calc(100vh - 240px);
    overflow: auto;
    .th,.td {
      &:nth-child(1) ,
      &:nth-child(6) {
        width: 30%;
      }
      &:nth-child(2) {
        width: 70%;
      }
    }
  }
}
</style>