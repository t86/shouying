<template>
  <div class="card-min-group">
    <div class="top" layout="row" layout-align="start center">
      <icon-button @click.native="showDrawerHandle(1)" text="新增" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="showDrawerHandle(2)" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="batchDelete" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
    </div>

    <!-- table -->
    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="start center">
            <div class="th">
              <el-checkbox v-model="checked" :indeterminate="indeterminate"
                @change="changeCheckboxHandle('all')">序号</el-checkbox>
            </div>
            <div class="th">模板名称</div>
            <div class="th">使用套餐数量</div>
            <div class="th">更新时间</div>
            <div class="th">创建时间</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" :class="{ 'selected': item.checked, 'gray': item.s == '无效' }"
            v-for="(item, index) in tableData" :key="index" layout="row" layout-align="start center">
            <div class="td">
              <el-checkbox v-model="item.checked" @change="changeCheckboxHandle('item')">{{ index + 1 }}</el-checkbox>
            </div>
            <div class="td">{{ item.n }}</div>
            <div class="td">
              <!-- <el-button type="text" @click="">{{ (item.ss && item.ss.length) || 0 }}</el-button> -->
              
              <el-popover
              placement="right"
              width="400"
              trigger="hover">
              <el-table :data="item.taocan">
                <el-table-column width="150" property="n1" label="一级分类"></el-table-column>
                <el-table-column width="150" property="n2" label="二级分类"></el-table-column>
                <el-table-column width="300" property="s" label="套餐名称"></el-table-column>
              </el-table>
              <el-button slot="reference" type="text">{{ (item.taocan && item.taocan.length) || 0}}</el-button>
            </el-popover>
              
            </div>
            <div class="td">{{ item.u }}</div>
            <div class="td">{{ item.c }}</div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>

    <drawerAddTaocanTemplate v-if="showDrawer" :type="type" :currentInfo="currentInfo" @closeDrawer="closeDrawer" />
  </div>
</template>
<script>
import IconButton from "@/components/IconButton.vue";
import DrawerAddTaocanTemplate from "@/components/DrawerAddTaocanTemplate.vue";

export default {
  data() {
    return {
      checked: false,
      indeterminate: false,
      tableData: [],
      currentInfo: {},
      type: 0,
      showDrawer: false
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await this.$api.BMS.Prd.get_prd_set_tpl_list()
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map(item => ({
            ...item,
            checked: false,
            // ss:[
            //   {
            //     id: 1,
            //     n: '套餐1',
            //     ss: [{id: 1, n: '套餐1-sub', ss:'商品1'}, {id: 2, n: '套餐1-sub2', ss:'商品2'}]
            //   }, {
            //     id: 2,
            //     n: '套餐2',
            //     ss: [{id: 2, n: '套餐2-sub', ss:'商品3'}, {id: 2, n: '套餐2-sub2', ss:'商品4'}]
            //   }
            // ]
          }));
          this.tableData.forEach(item => {
            let taocan = []
            if (item.ss) {
              item.ss.forEach(s => {
                if (s.ss) {
                  s.ss.forEach(s1 => {
                    if (s1.ss) {
                      s1.ss.forEach(t_name => {
                        taocan.push( {
                          n1: s.n,
                          n2: s1.n,
                          s: t_name
                        })
                      })
                    }
                  })
                }
              })
            }
            item.taocan = taocan
          });
          this.indeterminate = this.checked = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("get_prd_set_tpl_list", error);
      }
    },

    changeCheckboxHandle(type) {
      switch (type) {
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

    async batchDelete() {
      const checkedList = this.tableData.filter(item => item.checked);
      if (checkedList.length > 0) {
        this.$confirm('确认删除?', '确认', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(async () => {
          let ids = checkedList.map(item => item.id)
          const res = await this.$api.BMS.Prd.batch_del_prd_set_tpl({
            ids: ids
          })
          if (res.code == 1) {
            this.$message.warning('删除成功');
          } else {
            this.$message.warning(res.msg);
          }
          this.getTableData()
        }).catch(() => {
        });
      } else {
        return this.$message.warning("请至少选择一个删除");
      }
    },
    showDrawerHandle(type) {
      if (type === 2) {
        const checkedList = this.tableData.filter(item => item.checked);
        if (checkedList.length > 1 || checkedList.length == 0) {
          return this.$message.warning("请选择一个操作");
        }
        this.currentInfo = checkedList[0];
      } else if (type === 1) {
        this.currentInfo = {};
      }
      this.type = type
      this.showDrawer = true;
    },

    closeDrawer() {
      this.showDrawer = false;
      this.currentInfo = {};
      this.type = 0;
      this.getTableData(); // 刷新表格数据
    },
  },
  created() {
    this.getTableData();
  },
  components: {
    IconButton,
    DrawerAddTaocanTemplate
  },
  filters: {}
};
</script>
<style lang="less" scoped>
@import "../../../style/erp/table.less";
</style>
<style lang="less" scoped>
.card-min-group {
  padding: 20px;

  .top {
    background-color: #eee;
  }

  .table-content {
    width: 100%;
    max-height: calc(100vh - 180px);
    overflow: auto;

    .table {
      min-width: 1600px;

      .thead {
        .th {
          background-color: #f5f5f5;
        }
      }

      .tbody {
        .tr {
          &:nth-child(2n) {
            .td {
              background-color: #f5f5f5;
            }
          }

          &:nth-child(2n + 1) {
            .td {
              background-color: #f9f9f9;
            }
          }
        }
      }

      .th,
      .td {
        &:nth-child(3) {
          width: 180px;
        }

        &:nth-child(4) {
          width: 200px;
        }

        &:nth-child(5) {
          width: 200px;
        }

        &:nth-child(1) {
          width: 100px;
        }

        &:nth-child(2) {
          width: 300px;
        }
      }
    }
  }

}
</style>
