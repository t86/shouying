<template>
  <div class="erp-lib">
    <div class="top m-b-3" layout="row" layout-align="start center">
      <div class="coll" layout="row" layout-align="start center">
        <span class="label fs14">日期：</span>
        <el-date-picker style="width:140px" v-model="day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="选择日期"></el-date-picker>
        <div class="label fs14 m-l-3">仓库名称：</div>
        <div class="value">
          <el-select style="width:160px" v-model="libVal" size="small" placeholder="请选择">
            <el-option
              v-for="item in libOption"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>
      </div>
      <el-input v-model="keyword" size="small" style="width:200px;margin: 0 10px" placeholder="物料名称或简写"></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button type="primary" size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出Excel</el-button>
      <el-button type="primary" size="small" @click="showPrintPreview">打印</el-button>
    </div>

    <!-- 打印预览对话框 -->
    <el-dialog
      title="打印预览"
      :visible.sync="printPreviewVisible"
      width="1100px"
      :close-on-click-modal="false"
      custom-class="print-preview-dialog"
      @close="handlePrintPreviewClose"
    >
      <div class="preview-toolbar">
        <el-popover
          placement="bottom"
          trigger="click"
          width="360"
          popper-class="column-setting-popover"
        >
          <div class="column-settings">
            <el-checkbox-group v-model="visibleColumnKeys">
              <div
                class="column-group"
                v-for="group in columnSettingGroups"
                :key="group.key"
                v-if="group.columns.length"
              >
                <div class="group-title">{{ group.label }}</div>
                <div class="group-items">
                  <el-checkbox
                    v-for="column in group.columns"
                    :key="column.key"
                    :label="column.key"
                  >
                    {{ column.label }}
                  </el-checkbox>
                </div>
              </div>
            </el-checkbox-group>
            <div class="column-actions">
              <el-button type="text" size="mini" @click.stop="selectAllColumns">全选</el-button>
              <el-button type="text" size="mini" @click.stop="resetColumns">重置</el-button>
            </div>
          </div>
          <el-button slot="reference" size="small">列设置</el-button>
        </el-popover>
        <div class="orientation-toggle">
          <span class="label">打印方向：</span>
          <el-radio-group v-model="printOrientation" size="small">
            <el-radio-button label="portrait">竖向</el-radio-button>
            <el-radio-button label="landscape">横向</el-radio-button>
          </el-radio-group>
        </div>
      </div>
      <div class="print-preview-content" :class="printOrientation" id="printPreviewContent">
        <!-- 表头信息 -->
        <div class="print-header">
          <div class="print-title">仓库进销存报表</div>
          
        </div>
        <!-- 表格 -->
        <div class="print-table-wrapper">
          <table class="print-table">
            <thead>
              <tr v-if="orderedVisibleColumns.length" class="print-meta-row">
                <th :colspan="orderedVisibleColumns.length">
                  <div class="meta-info">
                    <span v-for="item in printMetaInfo" :key="item.label">
                      {{ item.label }}：{{ item.value || '--' }}
                    </span>
                  </div>
                </th>
              </tr>
              <tr>
                <template v-for="item in headerStructure">
                  <th
                    v-if="item.type === 'column' && isColumnVisible(item.key)"
                    :key="`header-${item.key}`"
                    rowspan="2"
                  >
                    {{ columnMap[item.key].label }}
                  </th>
                  <th
                    v-else-if="item.type === 'group' && getGroupVisibleColumns(item.key).length"
                    :key="`group-${item.key}`"
                    :colspan="getGroupVisibleColumns(item.key).length"
                    class="group-title"
                  >
                    {{ item.label }}
                  </th>
                </template>
              </tr>
              <tr>
                <template v-for="item in headerStructure">
                  <template v-if="item.type === 'group'">
                    <th
                      v-for="column in getGroupVisibleColumns(item.key)"
                      :key="`sub-col-${item.key}-${column.key}`"
                    >
                      {{ column.label }}
                    </th>
                  </template>
                </template>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in printTableData" :key="index">
                <td
                  v-for="column in orderedVisibleColumns"
                  :key="`${column.key}-${index}`"
                  :class="getCellClass(column)"
                >
                  {{ formatCellValue(item, column, index) }}
                </td>
              </tr>
              <tr v-if="printTableData.length === 0">
                <td :colspan="Math.max(orderedVisibleColumns.length, 1)" class="text-center">暂无数据</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="printPreviewVisible = false">关闭</el-button>
        <el-button type="primary" @click="doPrint">打印</el-button>
      </span>
    </el-dialog>

    <div class="table-content">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th" style="height: 80px; line-height: 80px;">序号</div>
            <div class="th" style="height: 80px; line-height: 80px;">仓库</div>
            <div class="th" style="height: 80px; line-height: 80px;">物料名称</div>
            <div class="th" style="height: 80px; line-height: 80px;">单位</div>
            <div class="th-group" style="flex: 1;">
                <div class="th-header" style="height: 40px; line-height: 40px; border-bottom: 1px solid #e8e8e8; text-align: center;">期初</div>
                <div class="th-sub" layout="row">
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">数量</div>
                </div>
            </div>
            <div class="th-group" style="flex: 5;">
                <div class="th-header" style="height: 40px; line-height: 40px; border-bottom: 1px solid #e8e8e8; text-align: center;">入库</div>
                <div class="th-sub" layout="row">
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">采购</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">调拨</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">充公</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">盘盈</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">其他</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">合计</div>
                </div>
            </div>
            <div class="th-group" style="flex: 6;">
                <div class="th-header" style="height: 40px; line-height: 40px; border-bottom: 1px solid #e8e8e8; text-align: center;">出库</div>
                <div class="th-sub" layout="row">
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">销售</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">调拨</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">其他</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">盘亏</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">报损</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 2;">供应商回收数量</div>
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">合计</div>
                </div>
            </div>
            <div class="th-group" style="flex: 1;">
                <div class="th-header" style="height: 40px; line-height: 40px; border-bottom: 1px solid #e8e8e8; text-align: center;">结存</div>
                <div class="th-sub" layout="row">
                    <div class="th" style="height: 40px; line-height: 40px; flex: 1;">数量</div>
                </div>
            </div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(item, index) in tableData" :key="index">
            <div class="td">{{index + 1}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.m}}</div>
            <div class="td">{{item.u}}</div>
            <!-- Opening -->
            <div class="td" style="flex: 1;">{{item.pc}}</div>
            <!-- In -->
            <div class="td" style="flex: 1;">{{item.ibc}}</div>
            <div class="td" style="flex: 1;">{{item.ioi}}</div>
            <div class="td" style="flex: 1;">{{item.icg}}</div>
            <div class="td" style="flex: 1;">{{item.ipy}}</div>
            <div class="td" style="flex: 1;">{{item.iqt}}</div>
            <div class="td" style="flex: 1;">{{item.ic}}</div>
            <!-- Out -->
            <div class="td" style="flex: 1;">{{item.os}}</div>
            <div class="td" style="flex: 1;">{{item.oo}}</div>
            <div class="td" style="flex: 1;">{{item.oqt}}</div>
            <div class="td" style="flex: 1;">{{item.opk}}</div>
            <div class="td" style="flex: 1;">{{item.obs}}</div>
            <div class="td" style="flex: 1;">{{item.og}}</div>
            <div class="td" style="flex: 1;">{{item.oc}}</div>
            <!-- Closing -->
            <div class="td" style="flex: 1;">{{item.nc}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
        <div class="pagination" v-if="total > 0">
            <el-pagination
                @current-change="handleCurrentChange"
                :current-page="page_num"
                :page-size="page_size"
                layout="total, prev, pager, next, jumper"
                :total="total">
            </el-pagination>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
const getDefaultColumnSettings = () => ([
  { key: 'index', label: '序号', group: 'base', align: 'center', defaultValue: '--', formatter: (_, rowIndex) => rowIndex + 1 },
  { key: 'store', label: '仓库', field: 's', group: 'base', align: 'center', defaultValue: '---' },
  { key: 'material', label: '物料名称', field: 'm', group: 'base', align: 'center', defaultValue: '---' },
  { key: 'unit', label: '单位', field: 'u', group: 'base', align: 'center', defaultValue: '---' },
  { key: 'opening', label: '期初数量', field: 'pc', group: 'base', align: 'right', defaultValue: 0 },
  { key: 'inPurchase', label: '采购', field: 'ibc', group: 'inbound', align: 'right', defaultValue: 0 },
  { key: 'inTransfer', label: '调拨(入)', field: 'ioi', group: 'inbound', align: 'right', defaultValue: 0 },
  { key: 'inSeized', label: '充公', field: 'icg', group: 'inbound', align: 'right', defaultValue: 0 },
  { key: 'inInventory', label: '盘盈', field: 'ipy', group: 'inbound', align: 'right', defaultValue: 0 },
  { key: 'inOther', label: '其他(入)', field: 'iqt', group: 'inbound', align: 'right', defaultValue: 0 },
  { key: 'inTotal', label: '入库合计', field: 'ic', group: 'inbound', align: 'right', defaultValue: 0 },
  { key: 'outSale', label: '销售', field: 'os', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'outTransfer', label: '调拨(出)', field: 'oo', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'outOther', label: '其他(出)', field: 'oqt', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'outLoss', label: '盘亏', field: 'opk', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'outDamage', label: '报损', field: 'obs', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'supplyCount', label: '供应商回收数量', field: 'og', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'outTotal', label: '出库合计', field: 'oc', group: 'outbound', align: 'right', defaultValue: 0 },
  { key: 'ending', label: '结存数量', field: 'nc', group: 'base', align: 'right', defaultValue: 0 }
])

const HEADER_STRUCTURE = [
  { type: 'column', key: 'index' },
  { type: 'column', key: 'store' },
  { type: 'column', key: 'material' },
  { type: 'column', key: 'unit' },
  { type: 'column', key: 'opening' },
  { type: 'group', key: 'inbound', label: '入库' },
  { type: 'group', key: 'outbound', label: '出库' },
  { type: 'column', key: 'ending' }
]

const COLUMN_GROUP_META = [
  { key: 'base', label: '基础信息' },
  { key: 'inbound', label: '入库' },
  { key: 'outbound', label: '出库' }
]

export default {
  data() {
    return {
      day: "",
      libVal: 0,
      libOption: [],
      keyword: '',
      tableData: [],
      page_num: 1,
      page_size: 20,
      total: 0,
      printPreviewVisible: false,
      printTableData: [],
      storeName: '店铺名称',
      printTime: '',
      columnSettings: getDefaultColumnSettings(),
      visibleColumnKeys: [],
      headerStructure: HEADER_STRUCTURE,
      printOrientation: 'landscape'
    };
  },
  computed: {
    columnMap() {
      return this.columnSettings.reduce((map, col) => {
        map[col.key] = col
        return map
      }, {})
    },
    visibleColumnSet() {
      return new Set(this.visibleColumnKeys)
    },
    columnSettingGroups() {
      return COLUMN_GROUP_META.map(meta => ({
        ...meta,
        columns: this.columnSettings.filter(col => col.group === meta.key)
      }))
    },
    orderedVisibleColumns() {
      const columns = []
      this.headerStructure.forEach(entry => {
        if (entry.type === 'column' && this.isColumnVisible(entry.key)) {
          const col = this.getColumnByKey(entry.key)
          if (col) {
            columns.push(col)
          }
        }
        if (entry.type === 'group') {
          const groupCols = this.getGroupVisibleColumns(entry.key)
          if (groupCols.length) {
            columns.push(...groupCols)
          }
        }
      })
      return columns
    },
    shopName() {
      const userInfo = (this.$store && this.$store.state && this.$store.state.userInfo) || {}
      return userInfo.org_name || userInfo.store_name || userInfo.shop_name || userInfo.name || '--'
    },
    printMetaInfo() {
      return [
        { label: '筛选日期', value: this.day || this.getDate() },
        { label: '仓库', value: this.libOption.find(item => item.id === this.libVal).n || '全部仓库' },
        { label: '打印时间', value: this.printTime }
      ]
    }
  },
  methods: {
    initColumnSelections() {
      this.visibleColumnKeys = this.columnSettings.map(col => col.key)
    },
    selectAllColumns() {
      this.visibleColumnKeys = this.columnSettings.map(col => col.key)
    },
    resetColumns() {
      this.selectAllColumns()
    },
    isColumnVisible(key) {
      return this.visibleColumnSet.has(key)
    },
    getGroupVisibleColumns(groupKey) {
      return this.columnSettings.filter(col => col.group === groupKey && this.isColumnVisible(col.key))
    },
    getColumnByKey(key) {
      return this.columnSettings.find(col => col.key === key)
    },
    formatCellValue(row, col, rowIndex) {
      if (typeof col.formatter === 'function') {
        return col.formatter(row, rowIndex)
      }
      if (!col.field) {
        return ''
      }
      const value = row[col.field]
      if (value === undefined || value === null || value === '') {
        return (col && col.defaultValue !== undefined) ? col.defaultValue : '--'
      }
      return value
    },
    getCellClass(col) {
      return {
        'text-right': col.align === 'right',
        'text-center': col.align === 'center'
      }
    },
    async getOption() {
      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_erpparam_items()
        if(res.code == 1) {
          this.libOption = [{
            id: 0,
            n: '全部'
          }, ...(res.data.stores || [])]
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取仓库列表option失败');
      }
    },

    async getTableData() {
      const params = {
        page_num: this.page_num,
        page_size: this.page_size,
        store_id: this.libVal * 1, //   int64    仓库id , 0 表示全部
        day: this.day,
        key: this.keyword || "" //  string   查询关键字
      };
      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_get_store_invt_reps(params)
        if(res.code == 1) {
          this.tableData = res.data.records || []
          this.total = res.data.row_cnt || 0
          this.page_num = res.data.page_num || 1
        } else {
          this.$message.warning(res.msg)
          this.tableData = []
          this.total = 0
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
        this.tableData = []
        this.total = 0
      }
    },

    handleCurrentChange(val) {
        this.page_num = val;
        this.getTableData();
    },

    async exportExcelHandle(){
      const params = {
        store_id: this.libVal * 1, //   int64    仓库id , 0 表示全部
        day: this.day,
        key: this.keyword || "" //  string   查询关键字
      };
      try {
        const res = await this.$api.ERP.rpt_erp.reqExportStoreInvtReps(params)
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    async showPrintPreview() {
      // 获取所有数据用于打印（不分页）
      const params = {
        page_num: 1,
        page_size: 999999, // 获取所有数据
        store_id: this.libVal * 1,
        day: this.day,
        key: this.keyword || ""
      };
      try {
        const res = await this.$api.ERP.rpt_erp.requestrpt_get_store_invt_reps(params)
        if(res.code == 1) {
          this.printTableData = res.data.records || []
          // 获取店铺名称
          const selectedStore = this.libOption.find(item => item.id === this.libVal)
          this.storeName = selectedStore ? selectedStore.n : '全部仓库'
          // 设置打印时间
          const now = new Date()
          const year = now.getFullYear()
          const month = (now.getMonth() + 1).toString().padStart(2, '0')
          const date = now.getDate().toString().padStart(2, '0')
          const hours = now.getHours().toString().padStart(2, '0')
          const minutes = now.getMinutes().toString().padStart(2, '0')
          const seconds = now.getSeconds().toString().padStart(2, '0')
          this.printTime = `${year}-${month}-${date} ${hours}:${minutes}:${seconds}`
          this.printPreviewVisible = true
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log("获取打印数据失败", error);
        this.$message.error("获取打印数据失败")
      }
    },

    handlePrintPreviewClose() {
      this.printTableData = []
    },

    doPrint() {
      // 创建打印窗口
      const printContent = document.getElementById('printPreviewContent').innerHTML
      const printWindow = window.open('', '_blank')
      printWindow.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>仓库进销存报表</title>
          <style>
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }
            body {
              font-family: Arial, "Microsoft YaHei", sans-serif;
              font-size: 12px;
              padding: 20px;
            }
            .print-header {
              margin-bottom: 20px;
            }
            .print-title {
              font-size: 18px;
              font-weight: bold;
              text-align: center;
              margin-bottom: 15px;
            }
            .print-info {
              display: flex;
              justify-content: space-between;
              margin-bottom: 10px;
            }
            .print-info-item {
              font-size: 12px;
            }
            .print-info-item .label {
              font-weight: bold;
            }
            .print-table-wrapper {
              width: 100%;
              overflow-x: auto;
            }
            .print-table {
              width: 100%;
              border-collapse: collapse;
              border: 1px solid #000;
            }
            .print-table th,
            .print-table td {
              border: 1px solid #000;
              padding: 6px 8px;
              text-align: center;
              font-size: 11px;
            }
            .print-table th {
              background-color: #f5f5f5;
              font-weight: bold;
            }
            .print-table tbody tr:nth-child(even) {
              background-color: #f9f9f9;
            }
            .print-table tbody tr:nth-child(odd) {
              background-color: #fff;
            }
            .text-right {
              text-align: right;
            }
            .text-center {
              text-align: center;
            }
            .print-preview-content.portrait .print-table {
              font-size: 11px;
            }
            .print-preview-content.landscape .print-table {
              font-size: 12px;
            }
            @media print {
              @page {
                size: A4 ${this.printOrientation};
                margin: 10mm;
              }
              body {
                padding: 0;
              }
            }
          </style>
        </head>
        <body>
          ${printContent}
        </body>
        </html>
      `)
      printWindow.document.close()
      printWindow.focus()
      // 等待内容加载完成后打印
      setTimeout(() => {
        printWindow.print()
        printWindow.close()
      }, 250)
    },

    getDate(dateNum = +new Date()) {
      const date = new Date(dateNum);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      return year + "-" + month + "-" + day;
    },

    resetHandle() {
      this.libVal = 0
      this.keyword = ''
      this.day = this.getDate()
      this.page_num = 1
      this.getOption()
      this.getTableData()
    }
  },
  created() {
    this.initColumnSelections()
    this.resetHandle()
  },
  components: {},
  filters: {}
};
</script>

<style lang="less" scoped>
@import '../../../../style/erp/table.less';
</style>
<style scoped lang="less">
.erp-lib{
  padding: 20px;
  .table-content {
    width: 100%;
    height: calc(100vh - 160px);
    overflow: auto;
    .table{
      width: 100%; // Auto width or fixed large width
      min-width: 1500px;
      .thead {
        .th {
          background-color: #f5f5f5;
          text-align: center;
          border-right: 1px solid #e8e8e8;
          &:last-child {
            border-right: none;
          }
        }
        .th-group {
            background-color: #f5f5f5;
            border-right: 1px solid #e8e8e8;
        }
      }
      .tbody {
        .tr{
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
      .th,.td {
        // Fixed columns
        &:nth-child(1) {
          width: 60px;
          flex: none;
        }
        &:nth-child(2) {
          width: 120px;
          flex: none;
        }
        &:nth-child(3) {
          width: 200px;
          flex: none;
        }
        &:nth-child(4){
          width: 60px;
          flex: none;
        }
        text-align: center;
        padding: 5px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
    }
    .pagination {
        margin-top: 10px;
        text-align: right;
    }
  }
}
</style>

<style>
/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
.el-range-editor--small .el-range-input {
  background-color: transparent;
}

.column-setting-popover {
  padding: 12px 16px;
  max-width: 380px;
}
</style>

<style lang="less" scoped>
.preview-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  gap: 12px;

  .orientation-toggle {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 13px;
    color: #40404e;
  }
}

.column-settings {
  max-height: 300px;
  overflow-y: auto;
  padding-right: 4px;

  .column-group {
    margin-bottom: 12px;

    .group-title {
      font-weight: 600;
      color: #40404e;
      margin-bottom: 6px;
    }

    .group-items {
      display: flex;
      flex-wrap: wrap;
      gap: 8px 12px;
    }
  }

  .column-actions {
    display: flex;
    justify-content: flex-end;
    gap: 8px;
  }
}

/* 打印预览对话框样式 */
.print-preview-content {
  max-height: 80vh;
  overflow-y: auto;
  
  .print-header {
    margin-bottom: 15px;
    padding-bottom: 15px;
    border-bottom: 1px solid #e8e8e8;
    
    .print-title {
      font-size: 18px;
      font-weight: bold;
      text-align: center;
      margin-bottom: 15px;
      color: #40404e;
    }
    
    .print-info {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      font-size: 13px;
      
      .print-info-item {
        margin-bottom: 8px;
        
        .label {
          font-weight: 600;
          color: #40404e;
          margin-right: 5px;
        }
        
        .value {
          color: #40404e;
        }
      }
    }
  }
  
  .print-table-wrapper {
    width: 100%;
    overflow-x: auto;
    
    .print-table {
      width: 100%;
      min-width: 100%;
      border-collapse: collapse;
      border: 1px solid #e8e8e8;
      font-size: 12px;
      table-layout: fixed;
      
      th, td {
        border: 1px solid #e8e8e8;
        padding: 8px;
        text-align: center;
        white-space: normal;
        word-break: break-all;
      }
      
      thead {
          .print-meta-row {
            th {
              background-color: #f0f2f5;
              font-weight: 500;
              padding: 10px 12px;
            }
            
            .meta-info {
              display: flex;
              flex-wrap: wrap;
              justify-content: space-between;
              gap: 10px;
              font-size: 13px;
              color: #40404e;
              
              span {
                min-width: 180px;
              }
            }
          }
          
        th {
          background-color: #f5f5f5;
          font-weight: 600;
          color: #40404e;
        }
      }
      
      tbody {
        tr {
          &:nth-child(even) {
            background-color: #f9f9f9;
          }
          
          &:nth-child(odd) {
            background-color: #fff;
          }
          
          td {
            color: #40404e;
            
            &.text-right {
              text-align: right;
              padding-right: 12px;
            }
            
            &.text-center {
              text-align: center;
            }
          }
        }
      }
    }
  }

  &.portrait {
    .print-table {
      font-size: 11px;
    }
  }

  &.landscape {
    .print-table {
      font-size: 12px;
    }
  }
}

/* 响应式适配 */
@media (orientation: portrait) {
  .print-preview-content {
    .print-table-wrapper {
      .print-table {
        font-size: 11px;
        
        th, td {
          padding: 6px;
        }
      }
    }
  }
}

@media (max-width: 900px) {
  .print-preview-content {
    .print-header {
      .print-title {
        font-size: 16px;
      }
      
      .print-info {
        font-size: 12px;
        flex-direction: column;
        
        .print-info-item {
          margin-bottom: 6px;
        }
      }
    }
    
    .print-table-wrapper {
      .print-table {
        font-size: 10px;
        
        th, td {
          padding: 4px;
        }
      }
    }
  }
}
</style>

<style>
/* 打印预览对话框全局样式 */
.print-preview-dialog {
  width: 1100px !important;
  max-width: 95vw;
  margin-top: 2vh !important;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.print-preview-dialog .el-dialog__body {
  padding: 15px;
  flex: 1;
  overflow-y: auto;
}

.print-preview-dialog .el-dialog__footer {
  flex-shrink: 0;
  padding: 12px 20px;
  border-top: 1px solid #f0f2f5;
  background: #fff;
  position: sticky;
  bottom: 0;
}

@media (max-width: 900px) {
  .print-preview-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
  }

  .print-preview-dialog .el-dialog__body {
    padding: 10px;
  }
}

@media (orientation: portrait) {
  .print-preview-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
  }
}
</style>
