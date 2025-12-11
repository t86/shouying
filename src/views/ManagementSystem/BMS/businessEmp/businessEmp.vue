<template>
  <div class="business-emp-page">
    <div class="page-header">
      <h2>商务组订位人</h2>
      <p class="page-desc">
        说明：已选列表的订位人在卡台消费时优先使用商品商务价（未配置商务价时，自动回落到普通价）。
      </p>
    </div>

    <div class="transfer-wrapper">
      <div class="panel-card left-panel">
        <div class="panel-header">
          <div>
            <span class="panel-title">待选员工列表</span>
          </div>
          <div class="panel-extra">
            <span class="count-text">共 {{ availableEmps.length }} 人</span>
          </div>
        </div>
        <div class="filter-form">
          <el-cascader
            class="filter-item"
            v-model="filterForm.deptPaths"
            :options="deptOptions"
            :props="deptProps"
            clearable
            placeholder="请选择部门（可多选）"
            popper-class="business-emp-dept-cascader"
            collapse-tags
          />
          <el-input
            class="filter-item search-input"
            v-model.trim="filterForm.keyword"
            maxlength="30"
            placeholder="请输入工号/姓名"
            clearable
          />
          <el-button
            class="filter-item"
            type="primary"
            size="medium"
            @click="fetchAvailableEmps"
          >
            查询
          </el-button>
          <el-button class="filter-item" size="medium" @click="handleResetFilters">
            重置
          </el-button>
        </div>

        <div class="table-wrapper" v-loading="availableLoading">
          <div class="table table-head" v-if="availableEmps.length">
            <div class="th checkbox">
              <el-checkbox
                :indeterminate="availableIndeterminate"
                :disabled="!hasSelectableRows"
                v-model="availableSelectAll"
                @change="handleToggleAll"
              ></el-checkbox>
            </div>
            <div class="th index">序号</div>
            <div class="th name">员工姓名</div>
            <div class="th dept">部门</div>
            <div class="th code">工号</div>
          </div>
          <div class="table-body" v-if="availableEmps.length">
            <div
              class="table table-row"
              v-for="(row, index) in availableEmps"
              :key="row.id"
            >
              <div class="td checkbox">
                <el-checkbox
                  v-model="row.checked"
                  :disabled="row.disabled"
                  @change="() => handleRowCheck(row)"
                ></el-checkbox>
              </div>
              <div class="td index">{{ index + 1 }}</div>
              <div class="td name">{{ row.name }}</div>
              <div class="td dept">{{ row.deptName || '—' }}</div>
              <div class="td code">{{ row.code || '—' }}</div>
            </div>
          </div>
          <el-empty
            v-else
            description="暂无可选员工"
            :image-size="120"
          />
        </div>

      </div>

      <div class="transfer-actions">
        <el-button
          type="primary"
          size="medium"
          :disabled="availableSelectedCount === 0"
          @click="handleAdd"
        >
          添加 &gt;&gt;
        </el-button>
      </div>

      <div class="panel-card right-panel">
        <div class="panel-header">
          <div>
            <span class="panel-title">已选员工列表</span>
            <span class="count-text">（{{ selectedEmps.length }} 人）</span>
          </div>
          <div class="selected-actions">
            <el-cascader
              class="filter-item dept-cascader"
              v-model="selectedFilter.deptPath"
              :options="deptOptions"
              :props="rightDeptProps"
              clearable
              placeholder="请选择部门"
              popper-class="business-emp-dept-cascader"
              size="medium"
            />
            <el-input
              class="filter-item search-input"
              v-model.trim="selectedFilter.keyword"
              maxlength="30"
              placeholder="请输入工号/姓名"
              clearable
              size="medium"
              @keyup.enter.native="fetchSelectedEmps"
            />
            <el-button
              class="filter-item"
              type="primary"
              size="medium"
              @click="fetchSelectedEmps"
            >
              查询
            </el-button>
            <el-button class="filter-item" size="medium" @click="handleResetSelectedFilters">
              重置
            </el-button>
            <el-button
              class="filter-item danger"
              type="danger"
              size="medium"
              :disabled="selectedSelectedCount === 0"
              @click="handleBatchRemove"
            >
              批量删除
            </el-button>
          </div>
        </div>
        <div class="table-wrapper" v-loading="selectedLoading">
          <div class="table table-head" v-if="selectedEmps.length">
            <div class="th checkbox">
              <el-checkbox
                :indeterminate="selectedIndeterminate"
                v-model="selectedSelectAll"
                @change="handleSelectedToggleAll"
              ></el-checkbox>
            </div>
            <div class="th index">序号</div>
            <div class="th name">员工姓名</div>
            <div class="th dept">部门</div>
            <div class="th code">工号</div>
            <div class="th action">操作</div>
          </div>
          <div class="table-body" v-if="selectedEmps.length">
            <div
              class="table table-row"
              v-for="(row, index) in selectedEmps"
              :key="row.id"
            >
              <div class="td checkbox">
                <el-checkbox
                  v-model="row.checked"
                  @change="() => handleSelectedRowCheck(row)"
                ></el-checkbox>
              </div>
              <div class="td index">{{ index + 1 }}</div>
              <div class="td name">{{ row.name }}</div>
              <div class="td dept">{{ row.deptName || '—' }}</div>
              <div class="td code">{{ row.code || '—' }}</div>
              <div class="td action">
                <span class="link" @click="handleRemove(row)">删除</span>
              </div>
            </div>
          </div>
          <el-empty
            v-else
            description="暂未选择员工"
            :image-size="120"
          />
        </div>

      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      availableLoading: false,
      selectedLoading: false,
      deptOptions: [],
      deptProps: {
        value: 'id',
        label: 'n',
        children: 'subs',
        emitPath: true,
        checkStrictly: true,
        multiple: true,
      },
      rightDeptProps: {
        value: 'id',
        label: 'n',
        children: 'subs',
        emitPath: true,
        checkStrictly: true,
        multiple: false,
      },
      filterForm: {
        deptPaths: [],
        keyword: '',
      },
      availableEmps: [],
      selectedEmps: [],
      availableSelectAll: false,
      availableIndeterminate: false,
      selectedFilter: {
        deptPath: [],
        keyword: '',
      },
      selectedSelectAll: false,
      selectedIndeterminate: false,
    };
  },
  computed: {
    availableSelectedCount() {
      return this.availableEmps.filter(
        (row) => row.checked && !row.disabled
      ).length;
    },
    hasSelectableRows() {
      return this.availableEmps.some((row) => !row.disabled);
    },
    currentSelectedIds() {
      return this.selectedEmps.map((item) => item.id);
    },
    selectedSelectedCount() {
      return this.selectedEmps.filter((row) => row.checked).length;
    },
  },
  created() {
    this.initPage();
  },
  methods: {
    async initPage() {
      await this.fetchDeptTree();
      await this.fetchSelectedEmps();
    },
    async fetchDeptTree() {
      try {
        const res = await this.$api.BMS.dept.requestDeptTree();
        if (res.code === 1) {
          this.deptOptions = this.formatDeptOptions(res.data || []);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取部门树失败', error);
      }
    },
    formatDeptOptions(list = []) {
      return list.map((item) => {
        const children = item.subs ? this.formatDeptOptions(item.subs) : undefined;
        return {
          ...item,
          subs: children,
        };
      });
    },
    async fetchSelectedEmps() {
      this.selectedLoading = true;
      try {
        const params = {
          key: this.selectedFilter.keyword || '',
          id: this.resolveSelectedDeptId(),
        };
        const res = await this.$api.BMS.businessEmp.reqGetBsSalesList(params);
        if (res.code === 1) {
          const payload = res.data || {};
          const list = Array.isArray(payload)
            ? payload
            : payload.records || payload.emps || [];
          this.selectedEmps = list.map((item) => ({
            id: item.id,
            name: item.n || '',
            deptName: item.d || '',
            code: item.c || '',
            checked: false,
          }));
          // 更新待选列表的禁用状态
          this.updateAvailableEmpsDisabledState();
          this.syncSelectedSelectionState();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取已选员工失败', error);
      } finally {
        this.selectedLoading = false;
      }
    },
    resolveSelectedDeptId() {
      const path = this.selectedFilter.deptPath || [];
      if (!Array.isArray(path) || path.length === 0) {
        return 0;
      }
      return path[path.length - 1] || 0;
    },
    async fetchAvailableEmps() {
      this.availableLoading = true;
      const params = {};
      const deptIds = this.resolveSelectedDeptIds();
      if (deptIds.length) {
        params.ids = deptIds;
      }
      params.key = this.filterForm.keyword || '';
      try {
        const res = await this.$api.BMS.emp.requestEmpList(params);
        if (res.code === 1) {
          const selectedSet = new Set(this.currentSelectedIds);
          const list = (res.data && res.data.emps) || [];
          this.availableEmps = list.map((item) => {
            const normalized = this.normalizeEmp(item);
            const disabled = selectedSet.has(normalized.id);
            return {
              ...normalized,
              checked: disabled,
              disabled,
            };
          });
          this.syncAvailableSelectionState();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取待选员工失败', error);
      } finally {
        this.availableLoading = false;
      }
    },
    resolveSelectedDeptIds() {
      const paths = this.filterForm.deptPaths;
      if (!paths || paths.length === 0) {
        return [];
      }
      if (Array.isArray(paths[0])) {
        return paths
          .map((path) => (Array.isArray(path) && path.length ? path[path.length - 1] : ''))
          .filter((id) => id !== '' && id !== undefined && id !== null);
      }
      return [paths[paths.length - 1]].filter((id) => id !== '' && id !== undefined && id !== null);
    },
    normalizeEmp(item = {}) {
      return {
        id: item.id,
        name: item.n || item.name || '',
        deptName: item.dn || item.deptName || '',
        code: item.cd || item.c || item.code || '',
      };
    },
    updateAvailableEmpsDisabledState() {
      const selectedSet = new Set(this.currentSelectedIds);
      this.availableEmps.forEach((row) => {
        const isSelected = selectedSet.has(row.id);
        row.disabled = isSelected;
        row.checked = isSelected;
      });
      this.syncAvailableSelectionState();
    },
    handleResetFilters() {
      this.filterForm = {
        deptPaths: [],
        keyword: '',
      };
      this.availableEmps = [];
      this.availableSelectAll = false;
      this.availableIndeterminate = false;
    },
    handleResetSelectedFilters() {
      this.selectedFilter = {
        deptPath: [],
        keyword: '',
      };
      this.selectedSelectAll = false;
      this.selectedIndeterminate = false;
      this.fetchSelectedEmps();
    },
    handleToggleAll(val) {
      this.availableEmps.forEach((row) => {
        if (!row.disabled) {
          row.checked = val;
        }
      });
      this.syncAvailableSelectionState();
    },
    handleRowCheck(row) {
      if (row.disabled) {
        row.checked = true;
        return;
      }
      this.syncAvailableSelectionState();
    },
    handleSelectedToggleAll(val) {
      this.selectedEmps.forEach((row) => {
        row.checked = val;
      });
      this.syncSelectedSelectionState();
    },
    handleSelectedRowCheck() {
      this.syncSelectedSelectionState();
    },
    syncAvailableSelectionState() {
      const selectable = this.availableEmps.filter((row) => !row.disabled);
      if (!selectable.length) {
        this.availableSelectAll = false;
        this.availableIndeterminate = false;
        return;
      }
      const selectedCount = selectable.filter((row) => row.checked).length;
      this.availableSelectAll = selectedCount === selectable.length;
      this.availableIndeterminate =
        selectedCount > 0 && selectedCount < selectable.length;
    },
    syncSelectedSelectionState() {
      if (!this.selectedEmps.length) {
        this.selectedSelectAll = false;
        this.selectedIndeterminate = false;
        return;
      }
      const selectedCount = this.selectedEmps.filter((row) => row.checked).length;
      this.selectedSelectAll = selectedCount === this.selectedEmps.length;
      this.selectedIndeterminate =
        selectedCount > 0 && selectedCount < this.selectedEmps.length;
    },
    async handleAdd() {
      const rows = this.availableEmps.filter(
        (row) => row.checked && !row.disabled
      );
      if (!rows.length) {
        return this.$message.warning('请选择需要添加的员工');
      }
      const ids = rows.map((row) => row.id);
      try {
        const res = await this.$api.BMS.businessEmp.reqBatchAddBsSales({ ids });
        if (res.code === 1) {
          this.$message.success('添加成功');
          await this.fetchSelectedEmps();
          this.updateAvailableEmpsDisabledState();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('批量添加商务组订位人失败', error);
        this.$message.warning('添加失败');
      }
    },
    async handleRemove(row) {
      try {
        const res = await this.$api.BMS.businessEmp.reqRemoveBsSales({ id: row.id });
        if (res.code === 1) {
          this.$message.success('删除成功');
          await this.fetchSelectedEmps();
          this.updateAvailableEmpsDisabledState();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('删除商务组订位人失败', error);
        this.$message.warning('删除失败');
      }
    },
    async handleBatchRemove() {
      const rows = this.selectedEmps.filter((row) => row.checked);
      if (!rows.length) {
        return this.$message.warning('请选择需要删除的员工');
      }
      this.selectedLoading = true;
      try {
        await Promise.all(
          rows.map((row) =>
            this.$api.BMS.businessEmp.reqRemoveBsSales({ id: row.id })
          )
        );
        this.$message.success('批量删除成功');
        await this.fetchSelectedEmps();
        this.updateAvailableEmpsDisabledState();
      } catch (error) {
        console.log('批量删除商务组订位人失败', error);
        this.$message.warning('删除失败');
      } finally {
        this.selectedLoading = false;
      }
    },
  },
};
</script>

<style scoped lang="less">
.business-emp-page {
  padding: 20px;
  color: #1a1a21;
  .page-header {
    margin-bottom: 16px;
    h2 {
      margin: 0;
      font-size: 20px;
      color: #303133;
    }
    .page-desc {
      margin-top: 8px;
      font-size: 14px;
      color: #606266;
    }
  }
}

.transfer-wrapper {
  display: flex;
  flex-wrap: nowrap;
  gap: 12px;
  align-items: stretch;
  
  @media (orientation: portrait) {
    flex-direction: column;
  }
}

.panel-card {
  flex: 1 1 0;
  background: #fff;
  border-radius: 8px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  max-width: 100%;
  
  @media (orientation: portrait) {
    width: 100%;
  }
}

.left-panel {
  flex: 0 0 54%;
  min-width: 520px;
  max-width: 58%;
  
  @media (orientation: portrait) {
    flex: 1 1 100%;
    min-width: auto;
    max-width: 100%;
  }
}

.right-panel {
  flex: 1 1 46%;
  min-width: 520px;
  
  @media (orientation: portrait) {
    flex: 1 1 100%;
    min-width: auto;
  }
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  .panel-title {
    font-size: 16px;
    font-weight: 600;
    color: #303133;
  }
  .count-text {
    font-size: 14px;
    color: #909399;
  }
}

.filter-form {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: nowrap;
  align-items: center;

  .filter-item {
    flex: 0 0 auto;
    width: 170px;
  }

  .filter-item.search-input {
    width: 200px;
  }

  @media (orientation: portrait) {
    flex-wrap: wrap;
    .filter-item,
    .filter-item.search-input {
      width: 100%;
    }
  }
}

.selected-actions {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;

  .filter-item {
    width: 160px;
    
    &.dept-cascader {
      width: 180px;
    }
  }

  .search-input {
    width: 200px;
  }

  @media (orientation: portrait) {
    width: 100%;
    justify-content: flex-start;
    .filter-item,
    .filter-item.dept-cascader,
    .search-input {
      width: 100%;
    }
  }
}

.table-wrapper {
  flex: 1;
  overflow: auto;
  min-height: 200px;
}

.table {
  width: 100%;
  border-collapse: collapse;
  
  &.table-head {
    display: flex;
    background: #f5f7fa;
    border-radius: 4px 4px 0 0;
    font-weight: 600;
    font-size: 14px;
    color: #303133;
  }
  
  &.table-body {
    display: block;
  }
  
  &.table-row {
    display: flex;
    border-bottom: 1px solid #ebeef5;
    transition: background-color 0.2s;
    
    &:hover {
      background-color: #f5f7fa;
    }
  }
  
  .th,
  .td {
    padding: 12px;
    text-align: left;
    font-size: 14px;
    
    &.checkbox {
      width: 60px;
      flex-shrink: 0;
    }
    
    &.index {
      width: 60px;
      flex-shrink: 0;
    }
    
    &.name {
      flex: 1;
      min-width: 120px;
    }
    
    &.dept {
      flex: 1;
      min-width: 150px;
    }
    
    &.code {
      flex: 1;
      min-width: 100px;
    }
    
    &.action {
      width: 80px;
      flex-shrink: 0;
    }
  }
  
  .th {
    color: #303133;
  }
  
  .td {
    color: #606266;
  }
}

.transfer-actions {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0 8px;
  flex: 0 0 110px;
  
  @media (orientation: portrait) {
    flex-direction: row;
    padding: 16px 0;
    flex: 1 1 auto;
  }
  
  .el-button {
    min-width: 96px;
    height: 38px;
  }
}

.tip-box {
  margin-top: 16px;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  line-height: 1.6;
  
  p {
    margin: 4px 0;
  }
  
  &.tip-warning {
    background: #fdf6ec;
    border: 1px solid #faecd8;
    color: #e6a23c;
  }
  
  &.tip-success {
    background: #f0f9ff;
    border: 1px solid #b3d8ff;
    color: #409eff;
  }
}

.link {
  color: #409eff;
  cursor: pointer;
  font-size: 14px;
  
  &:hover {
    color: #66b1ff;
  }
}

@media (max-width: 900px) {
  .business-emp-page {
    padding: 15px;
  }
  
  .panel-card {
    padding: 12px;
  }
}
</style>

<style lang="less">
// 商务组订位人部门下拉框样式 - 支持显示15个选项
// 关键：el-popper 容器本身也需要设置高度，否则会限制内部内容

// 直接对 el-popper 容器设置高度
.el-popper.business-emp-dept-cascader {
  max-height: 600px !important;
  height: auto !important;
  overflow: visible !important;
  
  // 内部面板
  .el-cascader-panel {
    max-height: 600px !important;
    height: auto !important;
  }
  
  // 菜单容器 - 这是关键，需要设置固定高度
  .el-cascader-menu {
    max-height: 600px !important;
    height: 600px !important;
  }
  
  // 滚动条容器 - 也需要设置高度
  .el-cascader-menu .el-scrollbar {
    max-height: 600px !important;
    height: 600px !important;
  }
  
  // 滚动包装器 - 这是实际限制高度的容器
  .el-cascader-menu .el-scrollbar__wrap {
    max-height: 600px !important;
    height: 600px !important;
    overflow-y: auto !important;
  }
  
  // 滚动视图
  .el-cascader-menu .el-scrollbar__view {
    max-height: 600px !important;
  }
  
  // 响应式：竖屏时适当减小高度
  @media (orientation: portrait) {
    max-height: 500px !important;
    
    .el-cascader-panel {
      max-height: 500px !important;
    }
    
    .el-cascader-menu {
      max-height: 500px !important;
      height: 500px !important;
    }
    
    .el-cascader-menu .el-scrollbar {
      max-height: 500px !important;
      height: 500px !important;
    }
    
    .el-cascader-menu .el-scrollbar__wrap {
      max-height: 500px !important;
      height: 500px !important;
    }
  }
}

// 备用选择器
.business-emp-dept-cascader {
  max-height: 600px !important;
  height: auto !important;
  
  .el-cascader-panel {
    max-height: 600px !important;
    height: auto !important;
  }
  
  .el-cascader-menu {
    max-height: 600px !important;
    height: 600px !important;
  }
  
  .el-cascader-menu .el-scrollbar {
    max-height: 600px !important;
    height: 600px !important;
  }
  
  .el-cascader-menu .el-scrollbar__wrap {
    max-height: 600px !important;
    height: 600px !important;
    overflow-y: auto !important;
  }
  
  @media (orientation: portrait) {
    max-height: 500px !important;
    
    .el-cascader-panel {
      max-height: 500px !important;
    }
    
    .el-cascader-menu {
      max-height: 500px !important;
      height: 500px !important;
    }
    
    .el-cascader-menu .el-scrollbar {
      max-height: 500px !important;
      height: 500px !important;
    }
    
    .el-cascader-menu .el-scrollbar__wrap {
      max-height: 500px !important;
      height: 500px !important;
    }
  }
}
</style>

