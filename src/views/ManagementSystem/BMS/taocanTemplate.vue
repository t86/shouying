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

              <el-popover placement="right" width="680" trigger="hover">
                <div class="popover-table">
                  <div class="popover-table-header">
                    <span>套餐详情</span>
                  </div>
                  <table class="custom-table">
                    <thead>
                      <tr>
                        <th width="180">一级分类</th>
                        <th width="250">二级分类</th>
                        <th>套餐名称</th>
                      </tr>
                    </thead>
                    <tbody>
                      <template v-for="(group, groupIndex) in groupedTaocan(item.taocan)">
                        <template v-for="(n2Item, n2Index) in group.n2s">
                          <tr>
                            <!-- 只在每组的第一行显示一级分类 -->
                            <td v-if="n2Index === 0" :rowspan="group.n2s.length">{{ group.n1 }}</td>
                            <td>{{ n2Item.n2 }}</td>
                            <td>
                              <el-tag v-for="(s, sIndex) in n2Item.s" 
                                :key="sIndex" 
                                size="small" 
                                style="margin: 2px">
                                {{ s }}
                              </el-tag>
                            </td>
                          </tr>
                        </template>
                      </template>
                    </tbody>
                  </table>
                </div>
                <el-button slot="reference" type="text">
                  {{ item.taocan.reduce((total, item) => total + (item.s ? item.s.length : 0), 0) }}
                </el-button>
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
                      taocan.push(
                        {
                          n1: s.n,
                          n2: s1.n,
                          s: s1.ss
                        }
                      )
                      // s1.ss.forEach(t_name => {
                      //   taocan.push( {
                      //     n1: s.n,
                      //     n2: s1.n,
                      //     s: t_name
                      //   })
                      // })
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

    groupedTaocan(taocan) {
      const grouped = [];
      let currentGroup = null;

      taocan.forEach(item => {
        if (!item.n1 || !item.n2 || !Array.isArray(item.s)) return;

        if (!currentGroup || currentGroup.n1 !== item.n1) {
          currentGroup = { n1: item.n1, n2s: [], totalRows: 0 };
          grouped.push(currentGroup);
        }

        let n2Group = currentGroup.n2s.find(n2 => n2.n2 === item.n2);
        if (!n2Group) {
          n2Group = { n2: item.n2, s: [], rows: 0 };
          currentGroup.n2s.push(n2Group);
        }

        n2Group.s.push(...item.s);
        n2Group.rows += item.s.length;
        currentGroup.totalRows += item.s.length;
      });
      console.log("grouped:", grouped);
      return grouped;
    }
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
@import "../../../style/taocan_tpl.less";

.popover-table {
  .popover-table-header {
    padding: 12px;
    border-bottom: 1px solid #EBEEF5;
    
    span {
      font-size: 14px;
      color: #303133;
      font-weight: 500;
    }
  }
  
  .custom-table {
    width: 100%;
    border-collapse: collapse;
    
    th, td {
      border: 1px solid #EBEEF5;
      padding: 12px;
      text-align: left;
      vertical-align: top;
      line-height: 1.4;
    }
    
    th {
      background-color: #F5F7FA;
      color: #909399;
      font-weight: 500;
      padding: 8px 12px;
    }
    
    tr:hover {
      background-color: transparent;
    }
    
    td {
      .el-tag {
        margin: 2px;
      }
    }
  }
}
</style>
