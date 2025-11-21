<template>
  <div class="onboarding-approval">
    <!-- 标签页 -->
    <div class="tabs-container">
      <el-tabs v-model="activeTab" @tab-click="handleTabClick">
        <el-tab-pane label="待审批" name="pending"></el-tab-pane>
        <el-tab-pane label="已通过" name="approved"></el-tab-pane>
        <el-tab-pane label="已驳回" name="rejected"></el-tab-pane>
      </el-tabs>
    </div>

    <!-- 操作按钮 -->
    <div class="action-buttons" v-if="activeTab === 'pending'">
      <el-button type="primary" @click="handleBatchApprove">批量通过</el-button>
      <el-button type="danger" @click="handleBatchReject">批量驳回</el-button>
    </div>

    <!-- 表格 -->
    <div class="table-container" ref="tableContainer">
      <el-table
        :data="tableData"
        v-loading="loading"
        @selection-change="handleSelectionChange"
        style="width: 100%"
        :height="tableHeight"
        :key="`table-${activeTab}-${tableData.length}`"
        border
        stripe
      >
        <el-table-column
          type="selection"
          width="55"
          v-if="activeTab === 'pending'"
        ></el-table-column>
        <el-table-column label="序号" width="60" align="center">
          <template slot-scope="scope">
            {{ (pagination.pageNum - 1) * pagination.pageSize + scope.$index + 1 }}
          </template>
        </el-table-column>
        <el-table-column prop="n" label="姓名" width="120">
          <template slot-scope="scope">
            {{ scope.row.n || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="np" label="拼音" width="100">
          <template slot-scope="scope">
            {{ scope.row.np || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="d" label="部门" min-width="150">
          <template slot-scope="scope">
            {{ scope.row.d || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="sn" label="岗位" width="120">
          <template slot-scope="scope">
            {{ scope.row.sn || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="s" label="性别" width="80" align="center">
          <template slot-scope="scope">
            {{ scope.row.s === 1 ? '男' : scope.row.s === 2 ? '女' : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="ue" label="直属上级" width="120">
          <template slot-scope="scope">
            {{ scope.row.ue || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="p" label="电话" width="130">
          <template slot-scope="scope">
            {{ scope.row.p || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="rn" label="真实姓名" width="120">
          <template slot-scope="scope">
            {{ scope.row.rn || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="r" label="申请时间" width="160">
          <template slot-scope="scope">
            {{ scope.row.r || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center" v-if="activeTab === 'pending'">
          <template slot-scope="scope">
            <el-button type="text" size="small" @click="handleEdit(scope.row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div
      class="pagination-container"
      v-show="pagination.total > 0"
    >
      <el-pagination
        background
        layout="total, sizes, prev, pager, next, jumper"
        :total="pagination.total"
        :current-page="pagination.pageNum"
        :page-size="pagination.pageSize"
        :page-sizes="pagination.pageSizes"
        :hide-on-single-page="false"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 编辑对话框 -->
    <el-dialog
      title="编辑"
      :visible.sync="editDialogVisible"
      width="800px"
      :close-on-click-modal="false"
      class="edit-dialog"
    >
      <el-form :model="editForm" label-width="120px" ref="editForm">
        <el-form-item label="姓名" required>
          <el-input v-model="editForm.name" placeholder="请输入姓名" maxlength="20"></el-input>
        </el-form-item>
        <el-form-item label="简拼">
          <el-input v-model="editForm.name_py" placeholder="简拼" disabled></el-input>
        </el-form-item>
        <el-form-item label="部门" required>
          <el-cascader
            v-model="editForm.dept_id"
            :options="deptOptions"
            :props="deptProps"
            :show-all-levels="false"
            placeholder="请选择部门"
            style="width: 100%"
          ></el-cascader>
        </el-form-item>
        <el-form-item label="岗位" required>
          <el-select v-model="editForm.station_id" placeholder="请选择岗位" style="width: 100%">
            <el-option
              v-for="item in stationOptions"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="性别" required>
          <el-radio-group v-model="editForm.sex">
            <el-radio :label="1">男</el-radio>
            <el-radio :label="2">女</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="员工直属上级">
          <el-select
            v-model="editForm.upper_emp_id"
            filterable
            reserve-keyword
            clearable
            default-first-option
            placeholder="输入姓名、工号或ID"
            :filter-method="filterUpperEmp"
            style="width: 100%"
          >
            <el-option
              v-for="item in filteredUpperEmpOptions"
              :key="`${item.id}-${item.n}`"
              :label="item.n ? `${item.id} - ${item.n}` : String(item.id)"
              :value="item.id"
            >
              <span>{{ item.n ? `${item.id} - ${item.n}` : item.id }}</span>
            </el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="电话">
          <el-input
            v-model="editForm.phone_num"
            placeholder="电话"
            disabled
            maxlength="11"
          ></el-input>
        </el-form-item>
        <el-form-item label="真实姓名">
          <el-input v-model="editForm.real_name" placeholder="请输入真实姓名" maxlength="20"></el-input>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="editDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSaveEdit">确定</el-button>
      </div>
    </el-dialog>

    <!-- 批量通过确认对话框 -->
    <el-dialog
      title="批量通过"
      :visible.sync="batchApproveDialogVisible"
      width="400px"
      :close-on-click-modal="false"
    >
      <p>确定批量通过审核?</p>
      <div slot="footer" class="dialog-footer">
        <el-button @click="batchApproveDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmBatchApprove">确定</el-button>
      </div>
    </el-dialog>

    <!-- 批量驳回确认对话框 -->
    <el-dialog
      title="批量驳回"
      :visible.sync="batchRejectDialogVisible"
      width="400px"
      :close-on-click-modal="false"
    >
      <p>确定批量驳回?</p>
      <div slot="footer" class="dialog-footer">
        <el-button @click="batchRejectDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmBatchReject">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'OnboardingApproval',
  data() {
    return {
      activeTab: 'pending',
      loading: false,
      tableData: [],
      selectedRows: [],
      editDialogVisible: false,
      batchApproveDialogVisible: false,
      batchRejectDialogVisible: false,
      pagination: {
        pageNum: 1,
        pageSize: 20,
        total: 0,
        pageSizes: [10, 20, 30, 50]
      },
      editForm: {
        id: '',
        name: '',
        name_py: '',
        dept_id: [],
        station_id: '',
        sex: 1,
        upper_emp_id: '',
        phone_num: '',
        real_name: ''
      },
      deptOptions: [],
      deptProps: {
        value: 'id',
        label: 'n',
        children: 'subs',
        expandTrigger: 'hover',
        leaf: 'leaf',
        checkStrictly: true, // 允许选择任意级别的部门
        emitPath: true
      },
      stationOptions: [],
      upperEmpOptions: [], // 所有上级员工选项
      filteredUpperEmpOptions: [], // 过滤后的上级员工选项
      upperEmpLoading: false,
      tableHeight: null, // 表格高度，null 表示自动计算
      currentEditDeptId: null // 当前编辑行的部门ID
    }
  },
  mounted() {
    this.loadData()
    this.loadDeptOptions()
    this.loadStationOptions()
    this.$nextTick(() => {
      this.calculateTableHeight()
      window.addEventListener('resize', this.calculateTableHeight)
    })
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.calculateTableHeight)
  },
  methods: {
    calculateTableHeight() {
      this.$nextTick(() => {
        if (!this.$refs.tableContainer) return
        
        const container = this.$refs.tableContainer
        const containerRect = container.getBoundingClientRect()
        const windowHeight = window.innerHeight
        
        // 计算可用高度：窗口高度 - 容器顶部距离窗口顶部的距离 - 底部边距
        // 减去一些安全边距，确保不会超出
        const availableHeight = windowHeight - containerRect.top - 20
        
        // 确保最小高度
        this.tableHeight = Math.max(availableHeight, 300)
      })
    },
    handleTabClick(tab) {
      this.activeTab = tab.name
      this.resetPagination()
      this.loadData()
      // 切换标签后重新计算表格高度
      this.$nextTick(() => {
        this.calculateTableHeight()
      })
    },
    loadData() {
      this.loading = true
      // 状态映射：1 申请中 2 已驳回 5 已通过
      const status = this.activeTab === 'pending' ? 1 : this.activeTab === 'approved' ? 5 : 2
      const { pageNum, pageSize } = this.pagination
      this.$api.BMS.emp.requestGetEmpRzList({
        s: status,
        page_num: pageNum,
        page_size: pageSize
      }).then(res => {
        if (res.code == 1) {
          const data = res.data || {}
          const records = data.records || []
          const currentPage = Number(data.page_num) || pageNum
          const currentSize = Number(data.page_size) || pageSize
          this.pagination.pageNum = currentPage
          this.pagination.pageSize = currentSize
          this.pagination.total = Number(data.row_cnt) || 0
          this.tableData = records.map((item, index) => ({
            ...item,
            index: (this.pagination.pageNum - 1) * this.pagination.pageSize + index + 1
          }))
          // 数据加载完成后，重新计算表格高度并强制更新
          this.$nextTick(() => {
            this.calculateTableHeight()
            this.$forceUpdate()
          })
        } else {
          this.$message.warning(res.msg)
        }
        this.loading = false
      }).catch(err => {
        console.error('加载数据失败', err)
        this.loading = false
      })
    },
    handleSizeChange(size) {
      if (this.pagination.pageSize === size) return
      this.pagination.pageSize = size
      this.pagination.pageNum = 1
      this.loadData()
    },
    handleCurrentChange(page) {
      if (this.pagination.pageNum === page) return
      this.pagination.pageNum = page
      this.loadData()
    },
    resetPagination() {
      this.pagination.pageNum = 1
      this.pagination.total = 0
    },
    loadDeptOptions() {
      // 编辑表单需要树形结构的部门数据，优先从resResultDataObj获取
      const deptInfo = this.$store.state.cardPageInfo.resResultDataObj.departmentInfo || []
      if (deptInfo.length > 0) {
        // 将部门数据转换为cascader需要的格式
        this.deptOptions = this.buildDeptTree(deptInfo)
      } else {
        // 如果resResultDataObj没有数据，使用API获取部门树
        this.$api.BMS.dept.requestDeptTree().then(res => {
          if (res.code == 1) {
            const deptTree = res.data || []
            // 为API返回的部门树也标记叶子节点
            this.markDeptTreeLeaf(deptTree)
            this.deptOptions = deptTree
          }
        })
      }
    },
    markDeptTreeLeaf(nodes) {
      // 为部门树标记叶子节点
      if (!nodes || !Array.isArray(nodes)) return
      nodes.forEach(node => {
        if (!node.subs || node.subs.length === 0) {
          node.leaf = true
        } else {
          node.leaf = false
          this.markDeptTreeLeaf(node.subs)
        }
      })
    },
    buildDeptTree(deptList) {
      // 将扁平部门列表转换为树形结构
      const map = {}
      const roots = []
      
      // 创建映射
      deptList.forEach(dept => {
        map[dept.id] = {
          id: dept.id,
          n: dept.name,
          subs: []
        }
      })
      
      // 构建树
      deptList.forEach(dept => {
        const node = map[dept.id]
        if (dept.parentId && map[dept.parentId]) {
          map[dept.parentId].subs.push(node)
        } else {
          roots.push(node)
        }
      })
      
      // 标记叶子节点（没有子节点的节点）
      const markLeaf = (nodes) => {
        nodes.forEach(node => {
          if (!node.subs || node.subs.length === 0) {
            node.leaf = true
          } else {
            node.leaf = false
            markLeaf(node.subs)
          }
        })
      }
      markLeaf(roots)
      
      return roots
    },
    loadStationOptions() {
      // 从resResultDataObj获取岗位数据
      const jobInfo = this.$store.state.cardPageInfo.resResultDataObj.jobInfo || []
      if (jobInfo.length > 0) {
        // 过滤有效岗位（status === 1），确保ID类型一致（统一为字符串）
        this.stationOptions = jobInfo
          .filter(item => item.status * 1 === 1)
          .map(item => ({
            id: String(item.id), // 统一转换为字符串
            n: item.name
          }))
      } else {
        // 如果resResultDataObj没有数据，使用API获取
        this.$api.BMS.emp.requestStationList({}).then(res => {
          if (res.code == 1) {
            // 确保API返回的数据格式一致
            const stations = res.data || []
            this.stationOptions = stations.map(item => ({
              id: String(item.id || item.value || item.station_id), // 统一转换为字符串
              n: item.name || item.label || item.station_name
            }))
          }
        })
      }
    },
    handleSelectionChange(selection) {
      this.selectedRows = selection
    },
    handleBatchApprove() {
      if (this.selectedRows.length === 0) {
        this.$message.warning('请选择要通过的记录')
        return
      }
      this.batchApproveDialogVisible = true
    },
    handleBatchReject() {
      if (this.selectedRows.length === 0) {
        this.$message.warning('请选择要驳回的记录')
        return
      }
      this.batchRejectDialogVisible = true
    },
    confirmBatchApprove() {
      const ids = this.selectedRows.map(row => row.id)
      this.$api.BMS.emp.requestEmpRzApproveBatchYes({ ids }).then(res => {
        if (res.code == 1) {
          this.$message.success('批量通过成功')
          this.batchApproveDialogVisible = false
          this.selectedRows = []
          this.loadData()
        } else {
          this.$message.warning(res.msg)
        }
      }).catch(err => {
        console.error('批量通过失败', err)
        this.$message.error('批量通过失败')
      })
    },
    confirmBatchReject() {
      const ids = this.selectedRows.map(row => row.id)
      this.$api.BMS.emp.requestEmpRzApproveBatchDeny({ ids }).then(res => {
        if (res.code == 1) {
          this.$message.success('批量驳回成功')
          this.batchRejectDialogVisible = false
          this.selectedRows = []
          this.loadData()
        } else {
          this.$message.warning(res.msg)
        }
      }).catch(err => {
        console.error('批量驳回失败', err)
        this.$message.error('批量驳回失败')
      })
    },
    handleEdit(row) {
      // 保存当前编辑行的部门ID
      this.currentEditDeptId = row.di || null
      
      // 字段说明：uei = 直属上级员工ID, ue = 直属上级员工名称
      // 调试：打印原始数据，确认字段映射
      console.log('编辑员工 - 原始数据:', {
        uei: row.uei,
        uei_type: typeof row.uei,
        ue: row.ue,
        ue_type: typeof row.ue
      })
      
      // 处理 upper_emp_id：确保是数字类型，与选项值类型一致
      let upperEmpId = ''
      if (row.uei !== null && row.uei !== undefined && row.uei !== '') {
        // 如果 uei 是字符串类型的数字，转换为数字
        const parsedId = Number(row.uei)
        if (!isNaN(parsedId) && parsedId !== 0) {
          upperEmpId = parsedId
        } else {
          // 如果 uei 不是数字，可能是字段映射错误，尝试使用 ue 作为ID
          console.warn('uei 不是有效的数字，尝试其他方式:', { uei: row.uei, ue: row.ue })
          // 如果 ue 是数字，可能是字段搞反了
          if (typeof row.ue === 'number' && row.ue !== 0) {
            upperEmpId = row.ue
            console.log('使用 ue 作为 ID:', upperEmpId)
          }
        }
      }
      
      // 获取名称：优先使用 ue，如果 ue 是数字且 uei 是字符串，则使用 uei 作为名称
      let upperEmpName = row.ue || ''
      if (typeof row.ue === 'number' && typeof row.uei === 'string') {
        // 如果字段可能搞反了，使用 uei 作为名称
        upperEmpName = row.uei
        console.log('使用 uei 作为名称:', upperEmpName)
      }
      
      console.log('处理后的数据:', {
        upperEmpId,
        upperEmpName
      })
      
      this.editForm = {
        id: row.id,
        name: row.n || '',
        name_py: row.np || '',
        dept_id: [],
        station_id: row.si ? String(row.si) : '', // 确保岗位ID是字符串类型
        sex: row.s || 1,
        upper_emp_id: upperEmpId, // 确保是数字类型，与选项值类型一致
        phone_num: row.p || '',
        real_name: row.rn || ''
      }
      
      // 设置部门路径
      this.setDeptPath(row.di)
      
      // 初始化上级员工选项（传入ID和名称）
      // ue = 直属上级员工名称，如果找不到匹配的，直接使用 ue 也可以
      this.initUpperEmpOptions(upperEmpId, upperEmpName)
      
      this.editDialogVisible = true
    },
    setDeptPath(deptId) {
      // 设置部门路径
      if (!deptId) {
        this.$set(this.editForm, 'dept_id', [])
        return
      }
      
      const setPath = () => {
        if (this.deptOptions.length > 0) {
          // 部门树已加载，查找路径
          const deptIdArray = this.findDeptPath(deptId, this.deptOptions)
          if (deptIdArray.length > 0) {
            // 确保路径数组中的ID类型一致
            this.$set(this.editForm, 'dept_id', deptIdArray)
          } else {
            // 如果找不到路径，尝试直接使用部门ID（可能是叶子节点）
            this.$set(this.editForm, 'dept_id', [deptId])
          }
        } else {
          // 部门树未加载，等待加载完成后再设置
          setTimeout(setPath, 100)
        }
      }
      
      if (this.deptOptions.length > 0) {
        setPath()
      } else {
        this.$nextTick(() => {
          setPath()
        })
      }
    },
    findDeptPath(deptId, deptTree) {
      // 递归查找部门路径，确保类型匹配
      if (!deptId || !deptTree || deptTree.length === 0) {
        return []
      }
      
      // 统一转换为字符串进行比较，避免类型不匹配
      const targetId = String(deptId)
      
      for (let dept of deptTree) {
        const currentId = String(dept.id)
        if (currentId === targetId) {
          // 找到目标节点，返回包含该节点的路径
          // 保持原始ID类型（可能是数字或字符串）
          return [dept.id]
        }
        if (dept.subs && dept.subs.length > 0) {
          const path = this.findDeptPath(deptId, dept.subs)
          if (path.length > 0) {
            // 找到子节点路径，将当前节点添加到路径开头
            return [dept.id, ...path]
          }
        }
      }
      return []
    },
    initUpperEmpOptions(upperEmpId, upperEmpName) {
      // 初始化上级员工选项，确保下拉框有数据可以显示
      const orderPersonInfo = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || []
      
      // 获取所有有效的上级员工（status === 1）
      const validEmps = orderPersonInfo
        .filter(emp => emp.status * 1 === 1)
        .slice(0, 50) // 初始加载前50个
        .map(emp => ({
          id: Number(emp.id), // 确保ID是数字类型，与表单值类型一致
          n: emp.name || ''
        }))
      
      // 如果当前有选中的上级员工，确保它在选项中
      if (upperEmpId !== null && upperEmpId !== undefined && upperEmpId !== '' && !isNaN(Number(upperEmpId))) {
        // 统一转换为数字进行比较，确保类型匹配
        const targetId = Number(upperEmpId)
        
        // 先在有效员工中查找
        let existingEmp = validEmps.find(emp => Number(emp.id) === targetId)
        
        if (!existingEmp) {
          // 如果当前选中的员工不在有效员工列表中，在所有员工中查找（包括无效的）
          const upperEmp = orderPersonInfo.find(emp => Number(emp.id) === targetId)
          
          if (upperEmp) {
            // 如果能在 orderPersonInfo 中找到，使用完整信息
            // 优先使用 orderPersonInfo 中的名称，如果为空则使用传入的名称
            existingEmp = {
              id: Number(upperEmp.id), // 确保是数字类型
              n: upperEmp.name || upperEmpName || '未知'
            }
            validEmps.unshift(existingEmp)
            console.log('在所有员工中找到匹配项:', existingEmp)
          } else if (upperEmpName) {
            // 如果找不到匹配的员工，使用传入的名称创建选项
            // 这样可以确保下拉框能显示 "ID - 名称" 格式
            existingEmp = {
              id: targetId,
              n: upperEmpName
            }
            validEmps.unshift(existingEmp)
            console.log('未找到匹配的员工，使用传入的名称创建选项:', existingEmp)
          } else {
            console.warn('未找到匹配的员工且没有提供名称:', { id: targetId })
          }
        } else {
          // 如果已存在，确保名称正确（如果名称为空，使用传入的名称）
          if (!existingEmp.n && upperEmpName) {
            existingEmp.n = upperEmpName
            console.log('更新已存在选项的名称:', existingEmp)
          }
          // 确保它在列表前面
          const index = validEmps.indexOf(existingEmp)
          if (index > 0) {
            validEmps.splice(index, 1)
            validEmps.unshift(existingEmp)
          }
          console.log('在有效员工中找到匹配项:', existingEmp)
        }
      } else if (upperEmpName && !upperEmpId) {
        // 如果只有名称没有ID，也创建一个选项（虽然这种情况应该很少）
        console.log('只有名称没有ID，创建选项:', { name: upperEmpName })
      }
      
      // 调试：打印最终的选项列表，特别是第一个选项（应该是当前选中的）
      console.log('最终的上级员工选项列表:', validEmps.slice(0, 5))
      console.log('当前选中的 upper_emp_id:', this.editForm.upper_emp_id, '类型:', typeof this.editForm.upper_emp_id)
      
      this.upperEmpOptions = validEmps
      // 初始化时，过滤后的选项等于所有选项
      this.filteredUpperEmpOptions = validEmps
      
      // 使用 $nextTick 确保 DOM 更新后，el-select 能正确显示选中的选项
      this.$nextTick(() => {
        // 强制更新 el-select 的显示
        // 如果 upper_emp_id 有值，确保对应的选项存在
        if (upperEmpId && this.editForm.upper_emp_id) {
          const selectedOption = this.upperEmpOptions.find(emp => Number(emp.id) === Number(this.editForm.upper_emp_id))
          if (selectedOption) {
            console.log('找到匹配的选项，应该能正确显示:', selectedOption)
          } else {
            console.warn('警告：未找到匹配的选项，upper_emp_id:', this.editForm.upper_emp_id)
          }
        }
      })
    },
    filterUpperEmp(query) {
      // 本地过滤方法，支持按ID、姓名、工号过滤
      if (!query || query === '') {
        this.filteredUpperEmpOptions = this.upperEmpOptions
        return
      }
      
      const search = query.toLowerCase()
      this.filteredUpperEmpOptions = this.upperEmpOptions.filter(emp => {
        const id = String(emp.id || '').toLowerCase()
        const name = (emp.n || '').toLowerCase()
        return id.includes(search) || name.includes(search)
      })
    },
    searchUpperEmp(query) {
      if (query !== '') {
        this.upperEmpLoading = true
        // 从resResultDataObj获取上级员工数据
        const orderPersonInfo = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || []
        // 过滤有效员工（status === 1）并模糊匹配姓名、工号或ID
        const filtered = orderPersonInfo
          .filter(emp => emp.status * 1 === 1)
          .filter(emp => {
            const name = (emp.name || '').toLowerCase()
            const code = (emp.code || '').toLowerCase()
            const id = String(emp.id || '').toLowerCase()
            const search = query.toLowerCase()
            return name.includes(search) || code.includes(search) || id.includes(search)
          })
          .slice(0, 50)
          .map(emp => ({
            id: emp.id,
            n: emp.name
          }))
        
        this.upperEmpOptions = filtered
        this.upperEmpLoading = false
      } else {
        // 如果搜索为空，恢复初始选项（包含当前选中的员工）
        this.initUpperEmpOptions(this.editForm.upper_emp_id, null)
      }
    },
    handleSaveEdit() {
      if (!this.editForm.name) {
        this.$message.warning('请输入姓名')
        return
      }
      if (!this.editForm.station_id) {
        this.$message.warning('请选择岗位')
        return
      }
      if (!this.editForm.dept_id || this.editForm.dept_id.length === 0) {
        this.$message.warning('请选择部门')
        return
      }
      const deptId = Array.isArray(this.editForm.dept_id) 
        ? this.editForm.dept_id[this.editForm.dept_id.length - 1] 
        : this.editForm.dept_id
      
      this.$api.BMS.emp.requestSaveEmpRzForApprove({
        id: this.editForm.id,
        name: this.editForm.name,
        dept_id: deptId * 1 || 0,
        station_id: this.editForm.station_id * 1 || 0,
        sex: this.editForm.sex,
        upper_emp_id: this.editForm.upper_emp_id * 1 || 0, // 保存时，空字符串转换为0
        real_name: this.editForm.real_name || ''
      }).then(res => {
        if (res.code == 1) {
          this.$message.success('编辑成功')
          this.editDialogVisible = false
          this.loadData()
        } else {
          this.$message.warning(res.msg)
        }
      }).catch(err => {
        console.error('编辑失败', err)
        this.$message.error('编辑失败')
      })
    }
  },
  watch: {
    'editForm.name'(newVal) {
      if (newVal) {
        this.$api.UtilAuth.util.requestutilpy({ str: newVal }).then(res => {
          this.editForm.name_py = res.data || ''
        })
      }
    },
    editDialogVisible(newVal) {
      if (newVal) {
        // 对话框打开时，延迟设置部门路径，确保DOM已渲染
        this.$nextTick(() => {
          setTimeout(() => {
            if (this.currentEditDeptId && (!this.editForm.dept_id || this.editForm.dept_id.length === 0)) {
              this.setDeptPath(this.currentEditDeptId)
            }
          }, 200)
        })
      } else {
        // 对话框关闭时，清空当前编辑的部门ID
        this.currentEditDeptId = null
      }
    },
    deptOptions: {
      handler() {
        // 当部门树加载完成时，如果正在编辑且部门路径还没设置，设置部门路径
        if (this.editDialogVisible && this.currentEditDeptId) {
          this.$nextTick(() => {
            setTimeout(() => {
              if (!this.editForm.dept_id || this.editForm.dept_id.length === 0) {
                this.setDeptPath(this.currentEditDeptId)
              }
            }, 100)
          })
        }
      },
      deep: true
    }
  }
}
</script>

<style scoped lang="less">
.onboarding-approval {
  width: 100%;
  height: 100%;
  padding: 15px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  background: #fff;

  .tabs-container {
    margin-bottom: 15px;
    
    /deep/ .el-tabs__header {
      margin: 0;
      border: none;
    }
    
    /deep/ .el-tabs__nav-wrap {
      border: none;
      &::after {
        display: none;
      }
    }
    
    /deep/ .el-tabs__nav-scroll {
      border: none;
    }
    
    /deep/ .el-tabs__nav {
      border: none;
    }
    
    /deep/ .el-tabs__item {
      height: 42px;
      line-height: 42px;
      font-size: 14px;
      padding: 0 20px;
    }
    
    /deep/ .el-tabs__active-bar {
      height: 2px;
    }
  }

  .action-buttons {
    margin-bottom: 15px;
    
    .el-button {
      height: 38px;
      padding: 0 20px;
      font-size: 14px;
      margin-right: 10px;
    }
  }

  .table-container {
    flex: 1;
    overflow: hidden;
    min-height: 0; // 确保 flex 子元素可以收缩
    display: flex;
    flex-direction: column;
    
    /deep/ .el-table {
      font-size: 14px;
      flex: 1;
      width: 100%;
      border: none;
      
      // 确保表格支持横向滚动
      .el-table__body-wrapper {
        overflow-x: auto;
        overflow-y: auto;
        border: none;
        
        &::after {
          display: none;
        }
        
        &::-webkit-scrollbar {
          width: 8px;
          height: 8px;
        }
        
        &::-webkit-scrollbar-thumb {
          background-color: #c0c4cc;
          border-radius: 4px;
        }
        
        &::-webkit-scrollbar-track {
          background-color: #f5f5f5;
        }
      }
      
      .el-table__header-wrapper {
        overflow-x: auto;
        border: none;
        
        &::after {
          display: none;
        }
        
        &::-webkit-scrollbar {
          width: 8px;
          height: 8px;
        }
        
        &::-webkit-scrollbar-thumb {
          background-color: #c0c4cc;
          border-radius: 4px;
        }
        
        &::-webkit-scrollbar-track {
          background-color: #f5f5f5;
        }
      }
      
      // 隐藏表格整体的边框
      &::before {
        display: none;
      }
      
      &::after {
        display: none;
      }
      
      .el-table__header th {
        background-color: #f5f5f5;
        color: #40404e;
        font-weight: 600;
        padding: 12px 0;
      }
      
      .el-table__body td {
        padding: 12px 0;
        color: #40404e;
      }
      
      .el-button--text {
        color: #409eff;
        font-size: 14px;
      }
    }
  }

  .notice-box {
    margin-top: 15px;
    padding: 15px;
    background-color: #fffbe6;
    border: 1px solid #ffe58f;
    border-radius: 6px;
    
    .notice-content {
      font-size: 13px;
      color: #40404e;
      line-height: 1.8;
      
      p {
        margin: 5px 0;
      }
      
      .notice-warning {
        color: #e6a23c;
        font-weight: 500;
      }
    }
  }

  .edit-dialog {
    /deep/ .el-dialog {
      max-width: 800px;
      width: 95%;
      margin-top: 2vh !important;
      max-height: 90vh;
      
      @media (orientation: portrait) {
        width: 95% !important;
        margin-top: 1vh !important;
      }
      
      @media (max-width: 900px) {
        width: 95% !important;
      }
    }
    
    /deep/ .el-dialog__body {
      max-height: calc(90vh - 120px);
      overflow-y: auto;
      padding: 15px;
    }
    
    /deep/ .el-form-item {
      margin-bottom: 15px;
    }
    
    /deep/ .el-input {
      height: 38px;
      
      .el-input__inner {
        height: 38px;
        line-height: 38px;
        font-size: 14px;
      }
    }
    
    /deep/ .el-select {
      .el-input__inner {
        height: 38px;
        line-height: 38px;
      }
    }
    
    /deep/ .el-cascader {
      .el-input__inner {
        height: 38px;
        line-height: 38px;
      }
    }
    
    .form-tip {
      font-size: 12px;
      color: #909399;
      margin-top: 5px;
      padding: 8px;
      background-color: #f0f9ff;
      border-radius: 4px;
      margin-left: 0;
    }
    
    /deep/ .el-radio {
      margin-right: 20px;
      font-size: 14px;
    }
    
    /deep/ .dialog-footer {
      .el-button {
        height: 38px;
        padding: 0 20px;
        font-size: 14px;
      }
    }
  }

  .pagination-container {
    display: flex;
    justify-content: flex-end;
    padding-top: 15px;
  }

  @media (orientation: portrait) {
    .pagination-container {
      justify-content: center;
      padding-top: 12px;
    }
  }
}

@media (orientation: portrait) {
  .onboarding-approval {
    padding: 10px;
    
    .tabs-container {
      /deep/ .el-tabs__item {
        padding: 0 15px;
        font-size: 13px;
      }
    }
    
    .action-buttons {
      .el-button {
        height: 36px;
        padding: 0 15px;
        font-size: 13px;
      }
    }
  }
}

@media (max-width: 900px) {
  .onboarding-approval {
    .table-container {
      /deep/ .el-table {
        font-size: 12px;
        
        .el-table__header th,
        .el-table__body td {
          padding: 8px 0;
        }
      }
    }
  }
}
</style>

