<template>
  <div class="business-emp-page">
    <div class="page-header">
      <h2>商务组订位人</h2>
    </div>

    <div class="transfer-wrapper">
      <div class="panel-card">
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
            v-model="filterForm.deptPath"
            :options="deptOptions"
            :props="deptProps"
            clearable
            placeholder="请选择部门"
          />
          <el-input
            class="filter-item"
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

      <div class="panel-card">
        <div class="panel-header">
          <div>
            <span class="panel-title">已选员工列表</span>
            <span class="count-text">（{{ selectedEmps.length }} 人）</span>
          </div>
        </div>
        <div class="table-wrapper" v-loading="selectedLoading">
          <div class="table table-head" v-if="selectedEmps.length">
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

    <div class="footer-actions">
      <el-button size="medium" @click="resetToServer">
        还原
      </el-button>
      <el-button
        type="primary"
        size="medium"
        :loading="saving"
        :disabled="!hasChanges"
        @click="handleSave"
      >
        保存
      </el-button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      availableLoading: false,
      selectedLoading: false,
      saving: false,
      deptOptions: [],
      deptProps: {
        value: 'id',
        label: 'n',
        children: 'subs',
        emitPath: true,
        checkStrictly: true,
      },
      filterForm: {
        deptPath: [],
        keyword: '',
      },
      availableEmps: [],
      selectedEmps: [],
      originalSelectedIds: [],
      availableSelectAll: false,
      availableIndeterminate: false,
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
    businessEmpStoreList() {
      const resObj =
        (this.$store.state.cardPageInfo &&
          this.$store.state.cardPageInfo.resResultDataObj) ||
        {};
      const list = resObj.businessEmpList || [];
      return list.map((item) => ({
        id: item.id,
        name: item.name || item.n || '',
        deptName: item.deptName || item.dn || '',
        code: item.code || item.c || '',
      }));
    },
    hasChanges() {
      if (this.currentSelectedIds.length !== this.originalSelectedIds.length) {
        return true;
      }
      const current = [...this.currentSelectedIds].sort().join(',');
      const original = [...this.originalSelectedIds].sort().join(',');
      return current !== original;
    },
  },
  created() {
    this.initPage();
  },
  methods: {
    async initPage() {
      await this.fetchDeptTree();
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
    syncSelectedFromStore() {
      this.selectedEmps = this.businessEmpStoreList.map((item) => ({
        ...item,
      }));
      this.originalSelectedIds = this.selectedEmps.map((item) => item.id);
    },
    async fetchAvailableEmps() {
      this.availableLoading = true;
      const params = {};
      const deptId =
        this.filterForm.deptPath.length > 0
          ? this.filterForm.deptPath[this.filterForm.deptPath.length - 1]
          : '';
      if (!deptId) {
        this.availableLoading = false;
        this.availableEmps = [];
        this.availableSelectAll = false;
        this.availableIndeterminate = false;
        this.$message.warning('请先选择部门再查询员工');
        return;
      }
      params.dept_id = deptId;
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
    normalizeEmp(item = {}) {
      return {
        id: item.id,
        name: item.n || item.name || '',
        deptName: item.dn || item.deptName || '',
        code: item.cd || item.c || item.code || '',
      };
    },
    handleResetFilters() {
      this.filterForm = {
        deptPath: [],
        keyword: '',
      };
      this.availableEmps = [];
      this.availableSelectAll = false;
      this.availableIndeterminate = false;
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
    handleAdd() {
      const rows = this.availableEmps.filter(
        (row) => row.checked && !row.disabled
      );
      if (!rows.length) {
        return this.$message.warning('请选择需要添加的员工');
      }
      const selectedSet = new Set(this.currentSelectedIds);
      rows.forEach((row) => {
        if (!selectedSet.has(row.id)) {
          this.selectedEmps.push({
            id: row.id,
            name: row.name,
            deptName: row.deptName,
            code: row.code,
          });
        }
        row.disabled = true;
        row.checked = true;
      });
      this.syncAvailableSelectionState();
    },
    handleRemove(row) {
      const index = this.selectedEmps.findIndex((item) => item.id === row.id);
      if (index > -1) {
        this.selectedEmps.splice(index, 1);
      }
      const target = this.availableEmps.find((item) => item.id === row.id);
      if (target) {
        target.disabled = false;
        target.checked = false;
      }
      this.syncAvailableSelectionState();
    },
    async handleSave() {
      this.$message.warning('后台暂未提供商务组订位人保存接口，请等待后端能力开放');
    },
    resetToServer() {
      this.syncSelectedFromStore();
    },
  },
  watch: {
    businessEmpStoreList: {
      handler() {
        this.syncSelectedFromStore();
      },
      immediate: true,
      deep: true,
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
      color: #f56c6c;
    }
  }
}

.transfer-wrapper {
  display: flex;
  flex-wrap: nowrap;
  gap: 16px;
  align-items: stretch;
}

.panel-card {
  flex: 1;
  background: #fff;
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
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
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 16px;
  .filter-item {
    flex: 1;
    min-width: 180px;
  }
}

.table-wrapper {
  flex: 1;
  border: 1px solid #ebeef5;
  border-radius: 6px;
  padding: 0 0 8px;
  min-height: 280px;
}

.table {
  display: grid;
  grid-template-columns: 60px 70px 1fr 1.2fr 1fr;
  padding: 0 16px;
  &.table-head {
    font-weight: 600;
    color: #606266;
    height: 48px;
    align-items: center;
  }
  &.table-row {
    padding: 12px 16px;
    align-items: center;
    border-top: 1px solid #f2f6fc;
    &:hover {
      background: #f5f7fa;
    }
  }
  .th,
  .td {
    font-size: 14px;
    color: #303133;
    &.checkbox {
      display: flex;
      align-items: center;
    }
    &.action .link {
      color: #409eff;
      cursor: pointer;
    }
  }
}

.table-body {
  max-height: 420px;
  overflow-y: auto;
}

.transfer-actions {
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 120px;
  .el-button {
    width: 110px;
    height: 42px;
  }
}

.tip-box {
  margin-top: 16px;
  padding: 12px 14px;
  border-radius: 6px;
  font-size: 13px;
  line-height: 22px;
  &.tip-warning {
    background: #fff7e6;
    color: #ad6800;
  }
  &.tip-success {
    background: #f0f9eb;
    color: #3a8b3a;
  }
}

.footer-actions {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

@media (orientation: portrait), (max-width: 1024px) {
  .transfer-wrapper {
    flex-direction: column;
  }
  .transfer-actions {
    order: 3;
    padding: 8px 0;
    .el-button {
      width: 100%;
    }
  }
  .panel-card {
    width: 100%;
  }
  .table {
    grid-template-columns: 60px 70px 1.1fr 1.1fr 0.8fr;
  }
}
</style>

