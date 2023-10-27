<template>
  <div class="pay-list p-6">
    <p class="red-color fs14 m-b-3">提示：请勾选门店使用的支付渠道，去掉勾选则无法使用该渠道结账；“自适应”代表自适应门店业务;长按选中条目拖动可以调整顺序</p>
    <div class="table-content" ref="tableRef">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">支付渠道</div>
            <div class="th">启用</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
            draggable="true"
            @dragstart="dragstart(item)"
            @dragenter="dragenter(item)"
            @dragend="dragend(item)"
          >
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.n}}</div>
            <div class="td">
              <el-checkbox v-if="item.id < 100 || item.id == 500" v-model="item.checked" @change="changeSelectHandle(item)"></el-checkbox>
              <span v-else>自适应</span>
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
</template>
 
<script>
export default {
  data() {
    return {
      tableData: [],
      dragInfo: {}, // 拖拽信息
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.paycnl.requestpaycnllist()
        if (res.code == 1) {
          const isAllNotChoose = (res.data || []).filter(item => item.id < 100 || item.id == 500).some(item => item.iu == 1)
          const result = (res.data || []).map(item => ({
            ...item,
            checked: isAllNotChoose ? item.iu == 1 : true
          }))
          this.tableData = [...result.filter(item => item.id < 100), ...result.filter(item => item.id == 500), ...result.filter(item => item.id > 100 && item.id != 500)]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("表格数据请求失败", error);
      }
    },

    async changeSelectHandle(itemInfo){
      const api = itemInfo.checked ? 'reqSelectItem' : 'reqNotSelectItem'
      const params = {
        id: itemInfo.id * 1 //  int64  支付渠道Id
      }

      try {
        const res = await this.$api.BMS.paycnl[api](params)
        if(res.code == 1) {
          this.$message.success('操作成功')
        }
      } catch (error) {
        console.log('操作支付渠道失败', error)
      }
    },
      // 记录初始信息
    dragstart(item) {
      this.dragInfo.oldItem = item;
    },
    // 记录过程中信息
    dragenter(item) {
      this.dragInfo.newItem = item;
    },
    // 做最终操作
    async dragend(item) {
      if (this.dragInfo.oldItem != this.dragInfo.newItem) {
        let oldIndex = this.tableData.findIndex(items => items.id == this.dragInfo.oldItem.id);
        let newIndex = this.tableData.findIndex(items => items.id == this.dragInfo.newItem.id);
        const downUp = oldIndex > newIndex ? 2 : 1;

        const params = {
          id: this.dragInfo.oldItem.id,
          dest_id: this.dragInfo.newItem.id,
          down_up: downUp
        }

        try {
          const res = await this.$api.BMS.paycnl.requestpaycnlmove(params)
          if(res.code == 1) {
            this.$message.success('更改位置成功')
            const newList = [...this.tableData]; // 中间数组，用于交换两个节点
            // 删除老的节点
            newList.splice(oldIndex, 1);
            //             // 在列表目标位置增加新的节点
            newList.splice(newIndex, 0, this.dragInfo.oldItem);
            //             // 更新this.List，触发transition-group的动画效果
            this.tableData = [...newList];
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('排序提交失败', error);
        }
      }
    },

    scrollBottom(){
      this.$nextTick(() => {
        const dom = this.$refs.tableRef
        dom && dom.scrollTo(0, 10000)
      })
    }
  },
  created(){
    this.getTableData()
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang='less'>
.table-content {
  height: calc(100vh - 160px);
  overflow: auto;
  .table {
    .th,.td {
      &:nth-child(1),
      &:nth-child(3) {
        width: 30%;
      }
    }
  }
}
</style>