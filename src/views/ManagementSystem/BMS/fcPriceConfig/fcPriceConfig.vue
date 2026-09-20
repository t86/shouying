<template>
  <div class="fc-price-config">
    <el-tabs v-model="tab" @tab-click="loadList">
      <el-tab-pane label="商品列表" name="products" />
      <el-tab-pane label="价格方案管理" name="plans" />
    </el-tabs>
    <template v-if="tab === 'products'">
      <p class="hint">如需添加新的价格方案，请在价格方案管理中添加。未配置方案价格时使用商品原单价。</p>
      <div class="toolbar" key="search-toolbar">
        <el-input v-model.trim="keyword" placeholder="商品名称/拼音" clearable @keyup.enter.native="loadList" />
        <el-button type="primary" @click="loadList">查询</el-button>
        <el-button @click="resetList">重置</el-button>
      </div>
    </template>
    <div class="toolbar" :key="tab + '-actions'">
      <el-button type="primary" @click="openEditor()">{{ tab === 'products' ? '添加商品' : '新增' }}</el-button>
      <el-button v-if="tab === 'plans'" :disabled="listSelection.length !== 1" @click="openEditor(listSelection[0])">编辑</el-button>
      <el-button :disabled="!listSelection.length || deleting" :loading="deleting" @click="deleteSelected">批量删除</el-button>
    </div>
    <el-table v-if="tab === 'products'" key="products" :data="products" border v-loading="loading" @selection-change="listSelection = $event">
      <el-table-column type="selection" width="45" />
      <el-table-column type="index" label="序号" width="60" />
      <el-table-column prop="n" label="商品名称" min-width="140" />
      <el-table-column prop="on" label="一级分类" min-width="100" />
      <el-table-column prop="tn" label="二级分类" min-width="100" />
      <el-table-column label="原单价（元）" width="115"><template slot-scope="{row}">{{ money(row.p) }}</template></el-table-column>
      <el-table-column v-for="plan in columns" :key="plan.id" :label="plan.n" min-width="185">
        <template slot-scope="{row}">
          <div class="price-cell">
            <el-input v-model="row.drafts[plan.id]" size="small" :disabled="savingPrices[cellKey(row, plan)]" aria-label="方案价格（元）" />
            <el-button type="text" :loading="savingPrices[cellKey(row, plan)]" @click="savePrice(row, plan)">保存</el-button>
          </div>
        </template>
      </el-table-column>
    </el-table>
    <el-table v-else key="plans" :data="plans" border v-loading="loading" @selection-change="listSelection = $event">
      <el-table-column type="selection" width="45" />
      <el-table-column type="index" label="序号" width="60" />
      <el-table-column prop="n" label="方案名称" min-width="180" />
      <el-table-column prop="e" label="包含员工数量" width="130" />
      <el-table-column prop="c" label="创建时间" min-width="170" />
      <el-table-column prop="u" label="更新时间" min-width="170" />
    </el-table>

    <el-dialog :title="editor.kind === 'products' ? '添加商品' : (editor.id ? '编辑价格方案' : '新增价格方案')" :visible.sync="editor.visible" width="90%" top="5vh" :close-on-click-modal="false" :before-close="closeEditor" append-to-body>
      <div v-if="editor.kind === 'plans'" class="toolbar">
        <label for="fc-plan-name"><span class="required">*</span>方案名称：</label>
        <el-input id="fc-plan-name" v-model.trim="editor.name" maxlength="50" :disabled="editor.removingId !== null || editor.saving" placeholder="请输入方案名称" />
      </div>
      <p v-if="editor.kind === 'plans'" class="hint">其他方案中的员工可先移除再添加。移除立即生效，加入当前方案需点击“确定”保存。</p>
      <div class="transfer">
        <section>
          <h3>待选{{ editor.kind === 'products' ? '商品' : '员工' }}列表</h3>
          <div class="toolbar filters">
            <el-cascader v-if="editor.kind === 'products'" v-model="editor.category" :options="editor.cates" :props="categoryProps" clearable placeholder="商品分类" :disabled="editor.removingId !== null || editor.saving || editor.initializing" />
            <el-cascader v-else v-model="editor.department" :options="departments" :props="departmentProps" clearable collapse-tags placeholder="部门（可多选）" :disabled="editor.removingId !== null || editor.saving || editor.initializing" />
            <el-input v-model.trim="editor.keyword" :placeholder="editor.kind === 'products' ? '商品名称/拼音' : '工号/姓名'" :disabled="editor.removingId !== null || editor.saving || editor.initializing" @keyup.enter.native="searchCandidates(false)" />
            <el-button type="primary" :disabled="editor.removingId !== null || editor.saving || editor.initializing" @click="searchCandidates(false)">查询</el-button>
            <el-button :disabled="editor.removingId !== null || editor.saving || editor.initializing" @click="resetCandidates">重置</el-button>
          </div>
          <el-table :key="editor.session" ref="candidates" :data="editor.candidates" height="390" border v-loading="editor.loading" @selection-change="candidateSelectionChanged">
            <el-table-column type="selection" width="42" :selectable="canSelect" />
            <el-table-column prop="n" :label="editor.kind === 'products' ? '商品名称' : '员工姓名'" min-width="105" />
            <el-table-column v-if="editor.kind === 'products'" prop="on" label="一级分类" min-width="85" />
            <el-table-column v-if="editor.kind === 'products'" prop="tn" label="二级分类" min-width="85" />
            <el-table-column v-if="editor.kind === 'products'" label="单价（元）" width="90"><template slot-scope="{row}">{{ money(row.p) }}</template></el-table-column>
            <el-table-column v-if="editor.kind === 'plans'" prop="d" label="部门" min-width="120" />
            <el-table-column v-if="editor.kind === 'plans'" prop="c" label="工号" width="90" />
            <el-table-column label="状态" min-width="170"><template slot-scope="{row}">
              <span>{{ candidateStatus(row) }}</span>
              <el-button v-if="editor.kind === 'plans' && (row.s == 1 || row.s == 2) && Number(row.p) > 0" type="text" class="remove-plan" :loading="editor.removingId === String(row.id)" :disabled="editor.removingId !== null || editor.saving || editor.loading" @click.stop="removeEmployeeFromPlan(row)">移除</el-button>
            </template></el-table-column>
          </el-table>
        </section>
        <el-button class="add-selection" type="primary" :disabled="editor.removingId !== null || !editor.checked.length || editor.saving || editor.loading" @click="addChecked">添加 &gt;</el-button>
        <section>
          <h3>已选{{ editor.kind === 'products' ? '商品' : '员工' }}列表（{{ editor.selected.length }}个）</h3>
          <el-table :data="editor.selected" height="445" border>
            <el-table-column type="index" label="序号" width="55" />
            <el-table-column prop="n" :label="editor.kind === 'products' ? '商品名称' : '员工姓名'" min-width="105" />
            <el-table-column v-if="editor.kind === 'products'" prop="on" label="一级分类" min-width="85" />
            <el-table-column v-if="editor.kind === 'products'" prop="tn" label="二级分类" min-width="85" />
            <el-table-column v-if="editor.kind === 'products'" label="单价（元）" width="90"><template slot-scope="{row}">{{ money(row.p) }}</template></el-table-column>
            <el-table-column v-if="editor.kind === 'plans'" prop="d" label="部门" min-width="120" />
            <el-table-column v-if="editor.kind === 'plans'" prop="c" label="工号" width="90" />
            <el-table-column label="操作" width="60"><template slot-scope="{row}"><el-button type="text" :disabled="editor.removingId !== null || editor.saving" @click="removeSelected(row)">移除</el-button></template></el-table-column>
          </el-table>
        </section>
      </div>
      <div slot="footer">
        <el-button :disabled="editor.removingId !== null || editor.saving" @click="closeEditor()">取消</el-button>
        <el-button type="primary" :loading="editor.saving" :disabled="editor.removingId !== null || editor.initializing || !editor.ready" @click="submitEditor">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api from '@/api/BMS/fcPrice';
import deptApi from '@/api/BMS/dept';
import { yuanToCents, centsToYuan, priceFor, isUnavailable, addSelection, responseData } from './model';

function emptyEditor(session) {
  return { visible: false, kind: 'products', id: 0, name: '', keyword: '', category: [], department: [],
    cates: [], candidates: [], checked: [], selected: [], session, request: 0,
    loading: false, initializing: false, saving: false, removingId: null, ready: false };
}
export default {
  name: 'FcPriceConfig',
  data() {
    return { tab: 'products', keyword: '', products: [], columns: [], plans: [], listSelection: [],
      loading: false, deleting: false, listRequest: 0, savingPrices: {}, departments: [], editor: emptyEditor(0),
      categoryProps: { value: 'id', label: 'n', children: 'cs', checkStrictly: true },
      departmentProps: { value: 'id', label: 'n', children: 'subs', checkStrictly: true, emitPath: false, multiple: true } };
  },
  created() { this.loadList(); },
  beforeDestroy() { this.listRequest++; this.editor.visible = false; },
  methods: {
    money: centsToYuan,
    cellKey(row, plan) { return `${row.id}:${plan.id}`; },
    error(error) { this.$message.error(error.message || '操作失败，请重试'); },
    async loadList() {
      const request = ++this.listRequest;
      const tab = this.tab;
      this.loading = true;
      this.listSelection = [];
      try {
        const data = responseData(await (tab === 'products' ? api.products({ key: this.keyword }) : api.plans()));
        if (request !== this.listRequest) return;
        if (tab === 'products') {
          this.columns = data.plans || [];
          this.products = (data.prds || []).map(row => {
            const drafts = {};
            this.columns.forEach(plan => { drafts[plan.id] = centsToYuan(priceFor(row, plan, data.prices || [])); });
            return { ...row, drafts };
          });
        } else this.plans = data.records || [];
      } catch (error) { if (request === this.listRequest) this.error(error); }
      finally { if (request === this.listRequest) this.loading = false; }
    },
    resetList() { this.keyword = ''; this.loadList(); },
    async savePrice(row, plan) {
      const key = this.cellKey(row, plan);
      if (this.savingPrices[key]) return;
      try {
        const amount = yuanToCents(row.drafts[plan.id]);
        this.$set(this.savingPrices, key, true);
        responseData(await api.savePrice({ prd_id: row.id, plan_id: plan.id, pay_amt: amount }));
        row.drafts[plan.id] = centsToYuan(amount);
        this.$message.success('价格已保存');
      } catch (error) { this.error(error); }
      finally { this.$set(this.savingPrices, key, false); }
    },
    async deleteSelected() {
      const tab = this.tab;
      const ids = this.listSelection.map(row => row.id);
      if (!ids.length || this.deleting) return;
      this.deleting = true;
      try {
        await this.$confirm(tab === 'products' ? '确认删除所选商品？删除后这些商品不再受方案价格限制。' : '确认删除所选价格方案？删除后相关员工不再受这些方案的价格限制。', '批量删除', { type: 'warning' });
        responseData(await (tab === 'products' ? api.deleteProducts({ ids }) : api.deletePlans({ ids })));
        this.$message.success('删除成功');
        this.loadList();
      } catch (error) { if (error !== 'cancel' && error !== 'close') this.error(error); }
      finally { this.deleting = false; }
    },
    async openEditor(row) {
      this.editor = { ...emptyEditor(this.editor.session + 1), visible: true, kind: this.tab,
        id: row ? row.id : 0, name: row ? row.n : '' };
      const editor = this.editor;
      this.searchCandidates(true);
      if (editor.kind === 'plans') {
        try {
          const data = responseData(await deptApi.requestDeptTree());
          if (this.editor === editor && editor.visible) this.departments = data;
        } catch (error) { if (this.editor === editor && editor.visible) this.error(error); }
      }
    },
    closeEditor(done) {
      if (this.editor.saving || this.editor.removingId !== null) return;
      this.editor.visible = false;
      this.editor.request++;
      if (typeof done === 'function') done();
    },
    async searchCandidates(initial) {
      const editor = this.editor;
      if (!editor.visible || editor.saving || editor.removingId !== null) return;
      initial = initial || !editor.ready;
      if (initial) { editor.keyword = ""; editor.department = []; editor.category = []; }
      const request = ++editor.request;
      editor.loading = true;
      if (initial) editor.initializing = true;
      editor.checked = [];
      try {
        let data;
        if (editor.kind === 'products') {
          data = responseData(await api.productItems({ one_cate_id: editor.category[0] || 0, two_cate_id: editor.category[1] || 0, key: editor.keyword }));
        } else {
          const departmentIds = editor.department.length ? editor.department.slice() : [0];
          const planId = editor.id;
          const keyword = editor.keyword;
          const records = new Map();
          for (const departmentId of departmentIds) {
            const result = responseData(await api.employeeItems({ plan_id: planId, dept_id: departmentId, key: keyword }));
            if (this.editor !== editor || !editor.visible || request !== editor.request) return;
            (result.records || []).forEach(row => records.set(String(row.id), row));
          }
          data = { records: Array.from(records.values()) };
        }
        if (this.editor !== editor || !editor.visible || request !== editor.request) return;
        editor.candidates = data.records || [];
        if (editor.kind === 'products') editor.cates = data.cates || [];
        if (initial && editor.kind === 'plans') editor.selected = editor.candidates.filter(row => Number(row.s) === 1);
        editor.ready = true;
        this.$nextTick(() => { if (this.editor === editor && editor.visible && request === editor.request && this.$refs.candidates) this.syncCandidateSelection(); });
      } catch (error) { if (this.editor === editor && editor.visible && request === editor.request) this.error(error); }
      finally {
        if (this.editor === editor && request === editor.request) { editor.loading = false; editor.initializing = false; }
      }
    },
    resetCandidates() {
      this.editor.keyword = ''; this.editor.category = []; this.editor.department = [];
      this.searchCandidates(!this.editor.ready);
    },
    candidateSelectionChanged(rows) {
      this.editor.checked = rows.filter(row => !isUnavailable(row, this.editor.kind, this.editor.selected));
    },
    syncCandidateSelection() {
      const editor = this.editor;
      const table = this.$refs.candidates;
      if (!table || !editor.visible) return;
      const checkedIds = new Set(editor.checked.map(row => String(row.id)));
      editor.candidates.forEach(row => {
        const checked = (editor.kind === "products" && Number(row.c) === 1) ||
          editor.selected.some(item => String(item.id) === String(row.id)) || checkedIds.has(String(row.id));
        table.toggleRowSelection(row, checked);
      });
    },
    canSelect(row) { return this.editor.removingId === null && !this.editor.saving && !this.editor.loading && !isUnavailable(row, this.editor.kind, this.editor.selected); },
    candidateStatus(row) {
      if (this.editor.kind === 'products' && Number(row.c) === 1) return '已配置';
      if (this.editor.kind === 'plans' && row.r) return row.r;
      if (this.editor.kind === 'plans' && Number(row.s) === 2) return '其他方案占用';
      return this.editor.selected.some(item => String(item.id) === String(row.id)) ? '已选' : '';
    },
    async removeEmployeeFromPlan(row) {
      const editor = this.editor;
      if (!editor.visible || editor.kind !== 'plans' || editor.saving || editor.loading || editor.removingId !== null || ![1, 2].includes(Number(row.s)) || !(Number(row.p) > 0)) return;
      const planId = row.p;
      editor.removingId = String(row.id);
      try {
        await this.$confirm(`确认将“${row.n || row.c || row.id}”从“${row.r || '原方案'}”移除？移除立即生效，取消当前编辑也不会恢复。`, '移除方案人员', { type: 'warning' });
        if (this.editor !== editor || !editor.visible) return;
        responseData(await api.removeEmployee({ plan_id: planId, emp_id: row.id }));
        if (this.editor !== editor) return;
        editor.request++;
        editor.selected = editor.selected.filter(item => String(item.id) !== String(row.id));
        editor.checked = editor.checked.filter(item => String(item.id) !== String(row.id));
        Object.assign(row, { s: 0, r: '', p: 0 });
        this.syncCandidateSelection();
        this.$message.success('已从原方案移除，可重新选择并添加');
        this.loadList();
      } catch (error) {
        if (error !== 'cancel' && error !== 'close' && this.editor === editor) this.error(error);
      } finally {
        editor.removingId = null;
      }
    },
    addChecked() {
      this.editor.selected = addSelection(this.editor.selected, this.editor.checked, this.editor.kind);
      this.editor.checked = [];
      this.syncCandidateSelection();
    },
    removeSelected(row) {
      this.editor.selected = this.editor.selected.filter(item => String(item.id) !== String(row.id));
      this.syncCandidateSelection();
    },
    async submitEditor() {
      const editor = this.editor;
      if (editor.removingId !== null || editor.saving || !editor.ready || editor.initializing) return;
      if (editor.kind === 'plans' && !editor.name.trim()) return this.$message.warning('请输入方案名称');
      if (editor.kind === 'products' && !editor.selected.length) return this.$message.warning('请选择商品');
      editor.saving = true;
      try {
        const ids = editor.selected.map(row => row.id);
        const params = { name: editor.name.trim(), emp_ids: ids };
        responseData(await (editor.kind === 'products' ? api.addProducts({ ids })
          : editor.id ? api.savePlan({ ...params, id: editor.id }) : api.addPlan(params)));
        if (this.editor !== editor) return;
        editor.visible = false;
        this.$message.success('保存成功');
        this.loadList();
      } catch (error) { if (this.editor === editor) this.error(error); }
      finally { editor.saving = false; }
    },
  },
};
</script>

<style scoped>
.fc-price-config { padding: 20px; background: #fff; min-height: calc(100vh - 110px); color: #303133; }
.toolbar { display: flex; align-items: center; gap: 10px; margin-bottom: 16px; }
.toolbar .el-input { width: 220px; }
.toolbar .el-button + .el-button { margin-left: 0; }
.remove-plan { margin-left: 8px; }
.hint { font-size: 13px; color: #909399; margin: 0 0 16px; }
.price-cell { display: flex; gap: 8px; align-items: center; }
.price-cell .el-input { min-width: 85px; }
.transfer { display: flex; gap: 16px; align-items: center; }
.transfer section { min-width: 0; flex: 1; border: 1px solid #ebeef5; padding: 12px; }
h3 { font-size: 14px; font-weight: 500; margin: 0 0 16px; }
.filters { flex-wrap: wrap; gap: 8px; }
.filters .el-input, .filters .el-cascader { width: 155px; }
.required { color: #f56c6c; }
.add-selection { flex-shrink: 0; }
@media (max-width: 1100px) { .transfer { gap: 8px; } .transfer section { padding: 8px; } }
</style>
