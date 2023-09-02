<template>
  <div class="station">
    <div class="station-controller">
      <icon-button @click.native="xingh" text="新增岗位" img="btn_add.png" colors="#383943"></icon-button>
      <icon-button @click.native="compileprinter" text="编辑" img="btn_edit.png" colors="#383943"></icon-button>
      <icon-button @click.native="noneffective" text="置为无效" img="btn_in_vain.png" colors="#383943"></icon-button>
      <icon-button @click.native="effective" text="置为有效" img="btn_effective.png" colors="#383943"></icon-button>
      <icon-button @click.native="printerdel" text="批量删除" img="btn_delete.png" colors="#6B2830"></icon-button>
      <characters-button @click.native="toEditSysPrivs" colors="#383943" wz="登录权限"></characters-button>
      <characters-button @click.native="toEditRegions" colors="#383943" wz="可点区域"></characters-button>
      <characters-button @click.native="toEditWaiterCates" colors="#383943" wz="可点商品"></characters-button>
      <characters-button @click.native="toEditCates(2)" colors="#383943" wz="优惠"></characters-button>
      <!-- <characters-button @click.native="toEditCates(5)" colors="#383943" wz='外部招待'></characters-button> -->
      <!-- <characters-button @click.native="toEditCates(3)" colors="#383943" wz='内部招待'></characters-button> -->
      <characters-button @click.native="toEditCates(3)" colors="#383943" wz="优惠2"></characters-button>
      <!-- <characters-button @click.native="toEditCates(6)" colors="#383943" wz='自用'></characters-button> -->
      <characters-button @click.native="toEditCates(8)" colors="#383943" wz="特饮小费关联商品"></characters-button>
      <characters-button @click.native="toEditStoreAdmins" colors="#383943" wz="erp系统权限"></characters-button>
      <characters-button @click.native="setAuthLimitHandle" colors="#383943" wz="配置权限"></characters-button>
      <characters-button @click.native="setLookOrderHandle" colors="#383943" wz="查单权限"></characters-button>
    </div>
    <div style="position: relative">
      <div class="zsykd" style="display: inline-block;">
        <table class="zhuixiaoi">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >全选&ensp;</el-checkbox>
              </th>
              <th>岗位名称</th>
              <th>权限</th>
              <th>岗位下员工数</th>
              <th>状态</th>
              <th>创建时间</th>
              <th>更新时间</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            ref="systemForm"
            @scroll="sysHandleScroll()"
            @mouseover="changeFlag(false)"
            :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}"
          >
            <tr
              v-for="(item,i) in tableData"
              :key="item.id"
              class="drag-list"
              :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
            >
              <td :style="{'color':item.s=='无效'?'#595959':''}">
                <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                  <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                </el-checkbox-group>
              </td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.p}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.ec || '---'}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.s}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c || '---'}}</td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.u}}</td>
            </tr>
          </tbody>
        </table>
        <div class="drag-list" v-if="tableData.length<1">
          <td class="nodata">
            <img src="@/assets/img/wu.png" alt />
            <div class="hint">暂无数据</div>
          </td>
        </div>
      </div>
      <!-- <div style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;">
        <table class="zhuixiaoi zhuixiaoi_l">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >全选&ensp;</el-checkbox>
              </th>
              <th>岗位名称</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            ref="externalForm"
            @scroll="exterHandleScroll()"
            @mouseover="changeFlag(true)"
            :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>MaxNumber?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`}"
          >
            <tr
              v-for="(item,i) in tableData"
              :key="item.id"
              class="drag-list"
              :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
            >
              <td :style="{'color':item.s=='无效'?'#595959':''}">
                <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                  <el-checkbox :label="item.id">{{i+1}}&emsp;&ensp;</el-checkbox>
                </el-checkbox-group>
              </td>
              <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
            </tr>
          </tbody>
        </table>
      </div> -->
    </div>

    <!-- 新增  编辑-->
    <div v-show="dialogFormVisible" class="dialogFormVisible">
      <el-dialog
        :title="title?'新增岗位':'编辑岗位'"
        @close="dialogFormVisible = false"
        :visible.sync="dialogFormVisible"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility">
            <div class="mandatory">
              <span class="reqfieldsd">*</span>岗位名称：
            </div>
            <el-input
              v-model="stationName"
              placeholder="请输入岗位名称"
              ref="selectsse"
              show-word-limit
              class="controlling"
              :class="form_rule_msg_name?'error':''"
              @blur="validator('name')"
            />
            <div class="cwts">{{form_rule_msg_name}}</div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFormVisible = false">取消</el-button>
          <el-button v-show="title" type="primary" @click="construction">新建</el-button>
          <el-button v-show="!title" type="primary" @click="saveprinter">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 无效有效删除 -->
    <div v-show="dialogFible" class="diagrgeesfelogFor">
      <el-dialog
        :title="srnr"
        :visible.sync="dialogFible"
        @close="dialogFible = false"
        :close-on-click-modal="false"
      >
        <div class="wwent" v-show="cwsm.cs.length>0">
          <span>以下对象存在依赖，需同步设置为{{srnr | pand}}</span>
          <characters-button
            @click.native="synchronizon"
            :disaed="kzsfjy"
            colors="#383943"
            :wz="`同步${srnr}`"
          ></characters-button>
        </div>
        <div class="wentlb" v-show="cwsm.cs.length>0">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>说明</th>
                <th>处理结果</th>
              </tr>
            </thead>
            <tbody class="limiting" :style="{'width':cwsm.cs.length>6?'calc(100% + 6px)':'100%'}">
              <tr v-for="(item,i) in cwsm.cs" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
                </td>
                <td v-show="item.jg == '成功'" style="color: #00BC72;">{{item.jg}}</td>
                <td v-show="item.jg == '---'">{{item.jg}}</td>
                <td v-show="item.jg == '失败'" style="color: #E13B50;">{{item.jg}}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="wwent" v-show="cwsm.ns.length>0">以下对象存在依赖，需人工处理依赖</div>
        <div class="wentlb danykz" v-show="cwsm.ns.length>0">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>说明</th>
              </tr>
            </thead>
            <tbody class="limiting" :style="{'width':cwsm.ns.length>6?'calc(100% + 6px)':'100%'}">
              <tr v-for="(item,i) in cwsm.ns" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item || '-----'"></ellipsis-tooltip>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFible = false">关闭</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 设置登录权限 -->
    <div v-show="editSysPrivs" class="dialogFormVisible editSysPrivs">
      <el-dialog
        title="登录权限"
        @close="editSysPrivs = false"
        :visible.sync="editSysPrivs"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div>
            <div class="mandatory">
              <span class="reqfieldsd">*</span>请勾可登录的系统：
            </div>
            <div class="m-t-4 m-l-2 sys_privs_check">
              <el-checkbox
                v-for="(item) in sysPrivsList"
                :key="item.id"
                :indeterminate="item.st==3"
                v-model="item.c"
                @change="sysPrivsChange($event, item)"
              >{{item.n}}</el-checkbox>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editSysPrivs = false">取消</el-button>
          <el-button type="primary" @click="saveSysPrivs">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 设置可点区域 -->
    <div v-show="editRegions" class="dialogFormVisible editRegions">
      <el-dialog
        title="可点区域"
        @close="editRegions = false"
        :visible.sync="editRegions"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="regions_compatibility compatibility">
            <div class="mandatory regions_mandatory">
              选择可点区域：
            </div>
            <div class="regions_check">
              <el-checkbox
                :indeterminate="isIndeterminateRegions"
                v-model="checkAllRegions"
                @change="handleCheckAllRegionsChange"
              >以下全部勾选&ensp;</el-checkbox>
              <el-checkbox
                v-for="(item) in regionsList"
                :key="item.id"
                :indeterminate="item.st==3"
                v-model="item.c"
                @change="regionsChange($event, item)"
              >{{item.n}}</el-checkbox>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editRegions = false">取消</el-button>
          <el-button type="primary" @click="saveRegions">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 管理仓库 -->
    <div v-show="editStoreAdmins" class="dialogFormVisible editStoreAdmins">
      <el-dialog
        title="管理仓库"
        @close="editStoreAdmins = false"
        :visible.sync="editStoreAdmins"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility storeAdmins_compatibility">
            <div class="mandatory storeAdmins_mandatory">
              <span class="reqfieldsd">*</span>请勾选erp仓库：
            </div>
            <div class="sys_privs_check">
              <el-checkbox
                v-for="(item) in storeAdminsList"
                :key="item.id"
                :indeterminate="item.st==3"
                v-model="item.c"
                @change="storeAdminsChange($event, item)"
              >{{item.n}}</el-checkbox>
            </div>
          </div>
          <div>
            <div class="mandatory storeAdmins_mandatory" style="width:240px">
              请勾选是否有查看空瓶仓权限：
            </div>
            <div class="sys_privs_check m-l-10 p-l-6">
              <el-checkbox
                :indeterminate="emptyLibIndeterminate"
                v-model="emptyLibCheckAll"
                @change="emptyLibIndeterminate=false"
              >空瓶仓管理</el-checkbox>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editStoreAdmins = false">取消</el-button>
          <el-button type="primary" @click="saveStoreAdmins">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 自用/花篮小费关联商品 -->
    <div v-show="editCates" class="dialogFormVisible editCates">
      <el-dialog
        :title="authType == 6?'自用':'花篮小费关联商品'"
        @close="editCates = false"
        :visible.sync="editCates"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility compatibility_editCates">
            <div class="mandatory mandatory_editCates" v-show="authType == 6">
              <span class="reqfieldsd">*</span>选择可自用商品：
            </div>
            <div class="mandatory mandatory_editCates" v-show="authType == 8">
              <span class="reqfieldsd">*</span>选择关联商品：
            </div>
            <classify-tree-three
              :showPrice="authType==6"
              :treeData="selCates"
              :resetStatus="resetStatus"
              @onChange="treeChange"
            ></classify-tree-three>
          </div>
          <div class="sys_privs_info" style="margin-top: 30px" v-show="authType == 6">说明：套餐商品不可自用</div>
          <div
            class="sys_privs_info"
            style="margin-top: 30px"
            v-show="authType == 8"
          >说明：只允许关联花篮、小费类的商品</div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editCates = false">取消</el-button>
          <el-button type="primary" @click="saveCates">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 可点商品 -->
    <div v-show="editWaiterCates" class="dialogFormVisible editWaiterCates">
      <el-dialog
        title="可点商品"
        @close="editWaiterCates = false"
        :visible.sync="editWaiterCates"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="sys_privs_info">说明：勾选“全部”后，如果有新增分类，该新增的分类默认选中</div>
          <div
            class="sys_privs_info"
            style="margin-top: 5px;margin-bottom: 15px; margin-left: 82px"
          >勾选“以下全部勾选”，如果有新增分类，该新增的分类默认不选中</div>
          <div class="compatibility compatibility_editWaiterCates">
            <div class="mandatory mandatory_editWaiterCates" style="line-height: 20px">
              <span class="reqfieldsd"></span>可点商品：
            </div>
            <el-checkbox
              :indeterminate="isIndeterminateAllPrdmode"
              v-model="checkAllPrdmode"
              @change="handleCheckAllPrdmodeChange"
            >全部&ensp;</el-checkbox>
          </div>
        </el-form>
        <el-form label-position="left" style="padding-top: 10px">
          <div class="compatibility compatibility_editWaiterCates">
            <div class="mandatory mandatory_editWaiterCates">
              <span class="reqfieldsd"></span>选择可点商品：
            </div>
            <classify-tree
              :treeData="waiterCates"
              :resetStatus="resetStatus"
              @onChange="waiterCatesChange"
            ></classify-tree>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editWaiterCates = false">取消</el-button>
          <el-button type="primary" @click="saveWaiterCates">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 优惠/优惠2关联商品 -->
    <div v-show="editCatesOther" class="dialogFormVisible editCatesOther">
      <el-dialog
        :title="catesTitle[authType]"
        @close="editCatesOther = false"
        :visible.sync="editCatesOther"
        :close-on-click-modal="false"
      >
        <div class="tab-header">
          <ul class="tab-item">
            <li class="tab-item-title tab-item-title-active"
            >优惠限制</li>
          </ul>
        </div>
        <div style="margin-top: 20px;" class="editCatesOtherTable">
          <div class="mandatory mandatory_editCates" style="margin-bottom: 10px;width:60px">
            <span class="reqfieldsd">*</span>选择限额限量：
          </div>
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>
                  <el-checkbox
                    :indeterminate="salesFreeLimitsIndeterminate"
                    v-model="salesFreeLimitsAll"
                    @change="salesFreeLimitsAllChange"
                  >全选&ensp;</el-checkbox>
                </th>
                <th>名称</th>
                <th>日限量</th>
                <th>日限额</th>
                <th>月限量</th>
                <th>月限额</th>
                <th>商品组数</th>
                <th>创建时间</th>
              </tr>
            </thead>
            <tbody class="limiting" :style="{'width':'100%'}">
              <tr
                v-for="(item,i) in salesFreeLimitsDatas"
                :key="item.id"
                class="drag-list"
                :class="item.check? 'drag-list-check':''"
              >
                <td :style="{'color':item.s=='无效'?'#595959':''}">
                  <el-checkbox
                    :indeterminate="item.st==3"
                    v-model="item.check"
                    @change="salesFreeLimitsSelChange($event, item)"
                  >{{i+1}}</el-checkbox>
                </td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.n}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.dc || '---'}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.dm || '---'}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.mc || '---'}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.mm || '---'}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.gc || '---'}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.c || '---'}}</td>
              </tr>
            </tbody>
          </table>
          <div class="drag-list" v-if="tableData.length<1">
            <td class="nodata">
              <img src="@/assets/img/wu.png" alt />
              <div class="hint">暂无数据</div>
            </td>
          </div>
        </div>

        <div style="margin-top: 20px;" class="editCatesOtherTable">
          <div class="mandatory mandatory_editCates" style="margin-bottom: 10px;width:460px" >
            <span class="reqfieldsd">*</span>可优惠商品列表（
            <span class="reqfieldsd">限额限量商品组中的商品即为该岗位可优惠的商品</span>）
          </div>
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th style="width:300px">商品名称</th>
                <th style="width:120px">一级分类</th>
                <th style="width:120px">二级分类</th>
                <th>单价</th>
              </tr>
            </thead>
            <tbody class="limiting" :style="{'width':'100%'}">
              <tr
                v-for="(item,i) in salesFreePrdList"
                :key="item.id"
                class="drag-list"
              >
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{i+1}}</td>
                <td style="width:300px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.p}}</td>
                <td style="width:120px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.o}}</td>
                <td style="width:120px" :style="{'color':item.s=='无效'?'#595959':''}">{{item.t}}</td>
                <td :style="{'color':item.s=='无效'?'#595959':''}">{{item.r}}</td>
              </tr>
            </tbody>
          </table>
          <div class="drag-list" v-if="salesFreePrdList.length<1">
            <td class="nodata">
              <img src="@/assets/img/wu.png" alt />
              <div class="hint">暂无数据</div>
            </td>
          </div>
        </div>


        <div layout="row" layout-align="end center">
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="editCatesOther = false">关闭</el-button>
          <el-button type="primary" class="m-r-10 m-t-6" @click="saveSalesFreeLimits">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 配置权限 -->
    <div v-show="authLimitInfo.show" class="dialogFormVisible editStoreAdmins">
      <el-dialog
        title="配置权限"
        @close="authLimitInfo.show = false"
        :visible.sync="authLimitInfo.show"
        :close-on-click-modal="false"
      >
        <el-form class="p-l-10" label-position="left">
          <div v-for="item in authLimitInfo.authLimitArr" :key="item.id">
            <el-checkbox
              v-model="item.checked"
              :indeterminate="item.indeterminate"
              @change="item.indeterminate = false"
            >{{item.n}}</el-checkbox>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="authLimitInfo.show = false">取消</el-button>
          <el-button type="primary" @click="saveAuthLimitHandle">确认</el-button>
        </span>
      </el-dialog>
    </div>

    <!-- 查单权限 -->
    <div v-show="lookOrderInfo.show" class="dialogFormVisible editRegions">
      <el-dialog
        title="查单权限"
        @close="lookOrderInfo.show = false"
        :visible.sync="lookOrderInfo.show"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="regions_compatibility compatibility">
            <div class="mandatory regions_mandatory">
              全场：
            </div>
            <div class="regions_check">
              <el-checkbox
                v-model="lookOrderInfo.all.checkAll"
                @change="lookOrderCheckBoxChange('allArea')"
              >全场查单</el-checkbox>
              
            </div>
          </div>
          <div class="regions_compatibility compatibility">
            <div class="mandatory regions_mandatory">
              选择可查单区域：
            </div>
            <div class="regions_check">
              <el-checkbox
                :indeterminate="lookOrderInfo.item.indeterminate"
                v-model="lookOrderInfo.item.checkAll"
                @change="lookOrderCheckBoxChange('all')"
              >以下全部勾选&ensp;</el-checkbox>
              <el-checkbox
                v-for="(item) in lookOrderInfo.areaList"
                :key="item.id"
                v-model="item.checked"
                @change="lookOrderCheckBoxChange('item')"
              >{{item.n}}</el-checkbox>
            </div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="lookOrderInfo.show = false">取消</el-button>
          <el-button type="primary" @click="submitLookOrderAreaHandle">确认</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
<script>
import { mapState, mapMutations } from "vuex";
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
import ClassifyTree from "./ClassifyTree.vue"; //根据路径导入组件
import ClassifyTreeThree from "./ClassifyTreeThree.vue"; //根据路径导入组件
export default {
  data() {
    return {
      List: [], //全部内容

      tableData: [], //岗位
      tableDataObj: [], //岗位对象结构
      dialogFormVisible: false, //控制新建岗位是否显示
      stationName: "", //岗位名称
      quantity: [], // 判断哪个要亮

      title: true, //

      multipleSelection: [], // 选中的内容
      isIndeterminate: false, // 供应商选择一部分
      checkAll: false, //供应商全选

      dialogFible: false, //控制错误2是否显示
      srnr: "", //文案
      cwsm: {
        ns: [], //不可操作列表
        cs: [] //可一键操作列表
      }, //错误2说明
      kzsfjy: false, //控制同步按钮是否禁用

      editSysPrivs: false, //设置系统角色是否显示
      sysPrivsList: [], // 系统角色数据

      editStoreAdmins: false, //设置管理仓库是否显示
      storeAdminsList: [], // 管理仓库数据

      /**
       * 空瓶仓权限管理begin
       */
      emptyLibCheckAll: false,
      emptyLibIndeterminate: false,
      /**
       * 空瓶仓权限管理end
       */


      authType: "", //2 优惠 3 优惠2 6 自用 8 花篮/特饮关联

      editCates: false, //设置是否显示 6 自用 8 花篮/特饮关联
      editCatesOther: false, //设置是否显示 2 优惠 3：优惠2
      selCates: [], // 商品数据
      salesFreeLimitsDatas: [], //限额限量数据
      salesFreePrdList: [],  // 限额限量商品
      salesFreeLimitsIndeterminate: false, //限额限量选择
      salesFreeLimitsAll: false, //限额限量全选

      editWaiterCates: false, //可点商品
      waiterCates: [], // 商品数据
      isIndeterminateAllPrdmode: false, //可点商品全部 半选状态
      checkAllPrdmode: false, //可点商品选择全部
      resetStatus: false,

      editRegions: false, //区域可点是否显示
      regionsList: [], // 区域可点数据
      isIndeterminateRegions: false, // 区域选择一部分
      checkAllRegions: false, //区域可点全选

      catesTitle: {
        2: "优惠",
        3: "优惠2"
        // 5: "外招招待"
      },

      // 配置权限相关
      authLimitInfo: {
        show: false,
        authLimitArr: []
      },

      // 配置权限相关
      lookOrderInfo: {
        show: false,
        all: {
          checkAll: false
        },
        item: {
          indeterminate: false,
          checkAll: false
        },
        areaList: []
      },

      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      form_rules: ["name"],
      form_rule_msg_name: "",

      flag: false
    };
  },
  mounted() {
    this.demand();
    this.RollMaxHeight(this.windowHeigh);
    var that = this;
    window.onresize = () => {
      return (() => {
        window.fullHeight = document.documentElement.clientHeight;
        window.fullWidth = document.documentElement.clientWidth;
        that.windowHeigh = window.fullHeight; // 高
        that.windowWidt = window.fullWidth; // 宽
      })();
    };
  },
  computed: {},
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton,
    ClassifyTree,
    ClassifyTreeThree
  },
  methods: {
    //滚动条监听
    changeFlag(flag) {
      this.flag = flag;
    },
    // 左右滚动条滚动同步
    sysHandleScroll() {
      if (!this.flag) {
        this.$refs.externalForm.scrollTop = this.$refs.systemForm.scrollTop;
      }
    },
    exterHandleScroll() {
      if (this.flag) {
        this.$refs.systemForm.scrollTop = this.$refs.externalForm.scrollTop;
      }
    },
    // form表单检测
    validator(val) {
      switch (val) {
        case "name":
          if (this.stationName == "") {
            this.form_rule_msg_name = "请输入岗位名称";
          } else if (this.$overall.character(this.stationName) > 20) {
            this.form_rule_msg_name = "输入文字长度超过10";
          } else {
            this.form_rule_msg_name = "";
          }
          break;
      }
    },

    async getSalesFreePrdList(){
      const params = {
        free_limit_ids: this.salesFreeLimitsDatas.filter(item => item.st == 1).map(item => item.id * 1) // []int64      //FreeLimitIds 限额限量配置列表
      }
      if(params.free_limit_ids.length == 0) {
        return this.salesFreePrdList = []
      }
      try {
        const res = await this.$api.BMS.station.reqGetChoosePrdList(params)
        if(res.code == 1) {
          this.salesFreePrdList = res.data.records || []
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取限额限量商品列表失败', error)
      }
    },
    
    //设置限额限量
    async saveSalesFreeLimits() {
      const params = {
        station_id: this.multipleSelection[0], // []int64   待操作角色Id列表
        free_limit_ids: this.salesFreeLimitsDatas.filter(item => item.st == 1).map(item => item.id * 1), // []int64   选中的限额限量组列表
      };

      try {
        const res =
          this.authType == 2
            ? await this.$api.BMS.station.reqSetGiveCateConfig(params)
            : await this.$api.BMS.station.reqSetGive2CateConfig(params);

        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: "success"
          });
          this.editCatesOther = false;
          this.weik();
          this.demand();
          this.authType = "";
          this.salesFreeLimitsDatas = [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("设置限额失败", error);
      }
    },

    //检测限额限量全选配置
    salesFreeLimitsSelChange(val, item) {
      let checkLen = 0,
        noCheck = 0,
        len = this.salesFreeLimitsDatas.length;
      this.salesFreeLimitsDatas.map(v => {
        if (v.id == item.id) {
          v.check = val;
          v.st = val ? 1 : 2;
        }
        if (+v.st === 1) checkLen = checkLen + 1;
        if (+v.st === 2) noCheck = noCheck + 1;
      });
      if (checkLen >= len) this.salesFreeLimitsAll = true;
      if (noCheck >= len) this.salesFreeLimitsAll = false;
      this.salesFreeLimitsIndeterminate =
        checkLen < len && noCheck < len ? true : false;
    },
    //检测限额限量配置
    salesFreeLimitsAllChange(val) {
      this.salesFreeLimitsDatas.map(item => {
        item.check = val;
        item.st = val ? 1 : 2;
      });
      this.salesFreeLimitsAll = val;
      this.salesFreeLimitsIndeterminate = false;
    },
    
    //获取营销/花篮岗位可授权商品限额限量配置, authType 2 优惠 3 优惠2
    async getSalesFreeLimits(callback) {
      const params = {
        id: this.multipleSelection[0] //    []int64   待读取岗位Id列表
      };
      try {
        const res =
          this.authType == 2
            ? await this.$api.BMS.station.reqGetGiveCateConfig(params)
            : await this.$api.BMS.station.reqGetGive2CateConfig(params);
        if (res.code == 1) {
          // 设置表格数据
          let checkLen = 0,
            noCheck = 0,
            len = res.data.free_limits.length;
          res.data.free_limits.map(item => {
            item.ost = item.st;
            item.check = item.st == 1 ? true : false;
            if (+item.st === 1) checkLen = checkLen + 1;
            if (+item.st === 2) noCheck = noCheck + 1;
          });
          this.salesFreeLimitsDatas = res.data.free_limits || [];
          if (checkLen >= len) this.salesFreeLimitsAll = true;
          if (noCheck >= len) this.salesFreeLimitsAll = false;
          this.salesFreeLimitsIndeterminate =
            checkLen < len && noCheck < len ? true : false;

            callback && callback()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取限额配置数据失败", error);
      }
    },
    //点击可点商品全部选项
    handleCheckAllPrdmodeChange(val) {
      setTimeout(() => {
        this.checkAllPrdmode = val;
        this.isIndeterminateAllPrdmode = false;
      });
      if (val) {
        this.resetStatus = !this.resetStatus;
        this.waiterCates.map(item => {
          item.st = 2;
          item.c = false;
          if (item.subs) {
            item.subs.map(v => {
              v.st = 2;
              v.c = false;
            });
          }
        });
      }
    },
    //点击可点商品按钮
    toEditWaiterCates() {
      if (this.multipleSelection.length > 0) {
        this.waiterCates = [];
        this.deptIds = [];
        this.$api.BMS.station
          .requestStationWaiterCates({
            station_ids: this.multipleSelection
          })
          .then(res => {
            if (res.code == 1) {
              res.data.cates.map(item => {
                if (item.subs) {
                  item.subs.map(v => {
                    v.ost = v.st;
                    v.c = v.st == 1 ? true : false;
                  });
                } else {
                  item.st = 2;
                  item.c = false;
                  item.subs = [];
                }
              });
              this.waiterCates = res.data.cates || [];
              this.editWaiterCates = true;
              setTimeout(() => {
                this.isIndeterminateAllPrdmode =
                  res.data.all_sel_type == 3 ? true : false;
                this.checkAllPrdmode =
                  res.data.all_sel_type == 1 ? true : false;
              });
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //监测可点商品数据变化
    waiterCatesChange(data) {
      this.waiterCates = data;
      this.isIndeterminateRegions = false;
      this.checkAllPrdmode = false;
    },
    //设置可点商品
    saveWaiterCates() {
      let sel_cates = [],
        unchange_cates = [],
        selected = [],
        all_prd_mode = 2;
      this.waiterCates.map(item => {
        item.subs &&
          item.subs.map(v => {
            if (v.ost == v.st && v.st != 2) {
              unchange_cates.push(v.id);
            }
            if (v.ost != v.st && v.st == 1) {
              sel_cates.push(v.id);
            }
            if (v.st != 2) {
              selected.push(v.id);
            }
          });
      });
      if (this.checkAllPrdmode) {
        all_prd_mode = 1;
      } else if (!this.isIndeterminateAllPrdmode && !this.checkAllPrdmode) {
        all_prd_mode = 2;
      } else {
        all_prd_mode = 3;
      }
      if (all_prd_mode == 2 && selected.length < 1) {
        this.$message.warning("请选择商品分类");
        return;
      }
      this.$api.BMS.station
        .requestStationSaveWaitCates({
          station_ids: this.multipleSelection,
          all_prd_mode,
          sel_cates,
          unchange_cates
        })
        .then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.weik();
            this.demand();
            this.waiterCates = [];
            this.editWaiterCates = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    //点击优惠(authType=2)、优惠2(authType=3)、花篮(authType=8)关联商品按钮
    async toEditCates(authType) {
      if (this.multipleSelection.length > 0) {
        this.authType = authType;
        if(authType == 8) {
          this.selCates = [];
          this.salesFreeLimitsDatas = [];
          this.deptIds = [];

          const params = {
            ids: this.multipleSelection //   []int64   待读取岗位Id列表
          };

          try {
            const res = await this.$api.BMS.station.reqGetGiveHlCate(params);
              // authType == 2
              //   ? await this.$api.BMS.station.reqGetGiveSaleCate(params)
              //   : authType == 3
              //   ? await this.$api.BMS.station.reqGetGive2SaleCate(params)
              //   : await this.$api.BMS.station.reqGetGiveHlCate(params);
            if (res.code == 1) {
              res.data.cates = res.data.cates || [];
              res.data.cates.map(item => {
                if (item.subs) {
                  item.subs.map(v => {
                    v.ost = v.st;
                    v.c = v.st == 1 ? true : false;
                  });
                } else {
                  item.st = 2;
                  item.c = false;
                  item.subs = [];
                }
              });
              this.selCates = res.data.cates || [];
              if ([2, 3, 5].includes(authType)) {
                this.editCatesOther = true;
              } else {
                this.editCates = true;
              }
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("获取关联商品信息失败", error);
          }
        } else {
          if(this.multipleSelection.length != 1) return this.$message.warning('请选择一个进行操作')
          this.getSalesFreeLimits(() => {
            this.editCatesOther = true;
          });
        }
        
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //监测自用/花篮关联商品数据变化
    treeChange(data) {
      this.selCates = data;
    },
    // 花篮关联商品
    async saveCates() {

      try {
        const sel_prds = [];
        const unchange_prds = [];
        this.selCates.forEach(el => {
          el.subs &&
            el.subs.forEach(ele => {
              ele.prds &&
                ele.prds.forEach(element => {
                  if (element.st == 1) sel_prds.push(element.id * 1);
                  if (element.st == 3) unchange_prds.push(element.id * 1);
                });
            });
        });
        const paramsData = {
          station_ids: this.multipleSelection, // []int64      //StationIds 角色Id列表
          sel_prds, //   []int64      //SelPrds 选中的商品列表
          unchange_prds // []int64      //UnchangePrds 不修改的商品列表
        };
        const res = await this.$api.BMS.station.reqSetGiveHlCate(paramsData);
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: "success"
          });
          this.editCates = false;
          this.weik();
          this.demand();
          this.authType = "";
          this.selCates = [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("保存失败", error);
      }
    },
    //点击管理仓库按钮
    toEditStoreAdmins() {
      if (this.multipleSelection.length > 0) {
        this.deptIds = [];
        this.$api.BMS.station
          .requestStationStoreAdmins({
            station_ids: this.multipleSelection
          })
          .then(res => {
            if (res.code == 1) {
              (res.data.store_admins || []).map(item => {
                item.ost = item.st;
                item.c = item.st == 1 ? true : false;
              });
              this.storeAdminsList = res.data.store_admins || [];
              this.emptyLibCheckAll = res.data.rtn_bt_sel_type == 1  // 空瓶仓全部选中
              this.emptyLibIndeterminate = res.data.rtn_bt_sel_type == 3  // 空瓶仓半选
              this.editStoreAdmins = true;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //监测管理仓库数据变化
    storeAdminsChange(val, item) {
      this.storeAdminsList.map(v => {
        if (v.id == item.id) {
          v.c = val;
          v.st = val ? 1 : 2;
        }
      });
    },
    //设置管理仓库
    saveStoreAdmins() {
      let sel_stores = [],
        unchange_stores = [],
        selected = [];
      this.storeAdminsList.map(item => {
        if (item.ost == item.st && item.st != 2) {
          unchange_stores.push(item.id);
        }
        if (item.ost != item.st && item.st == 1) {
          sel_stores.push(item.id);
        }
        if (item.st != 2) {
          selected.push(item.id);
        }
      });
      if (selected.length < 1) {
        this.$message.warning("请选择仓库");
        return;
      }
      this.$api.BMS.station
        .requestStationSaveStoreAdmins({
          station_ids: this.multipleSelection,
          sel_stores,
          unchange_stores,
          rtn_bt_sel_type: this.emptyLibCheckAll ? 1 : (this.emptyLibIndeterminate ? 3 : 2) //  int   空瓶仓管理权限 1 选中 2 不选 3 部分选中
        })
        .then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.weik();
            this.demand();
            this.storeAdminsList = [];
            this.editStoreAdmins = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    //点击可点区域按钮
    toEditRegions() {
      if (this.multipleSelection.length > 0) {
        this.deptIds = [];
        this.$api.BMS.station
          .requestStationWaiterRegions({
            station_ids: this.multipleSelection
          })
          .then(res => {
            if (res.code == 1) {
              let checkLen = 0,
                noCheck = 0,
                len = res.data.length;
              res.data.map(item => {
                item.ost = item.st;
                item.c = item.st == 1 ? true : false;
                if (+item.st === 1) checkLen = checkLen + 1;
                if (+item.st === 2) noCheck = noCheck + 1;
              });
              this.regionsList = res.data || [];
              this.editRegions = true;
              if (checkLen >= len) this.checkAllRegions = true;
              if (noCheck >= len) this.checkAllRegions = false;
              this.isIndeterminateRegions =
                checkLen < len && noCheck < len ? true : false;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //监测可点区域数据变化
    regionsChange(val, item) {
      let checkLen = 0,
        noCheck = 0,
        len = this.regionsList.length;
      this.regionsList.map(v => {
        if (v.id == item.id) {
          v.c = val;
          v.st = val ? 1 : 2;
        }
        if (+v.st === 1) checkLen = checkLen + 1;
        if (+v.st === 2) noCheck = noCheck + 1;
      });
      if (checkLen >= len) this.checkAllRegions = true;
      if (noCheck >= len) this.checkAllRegions = false;
      this.isIndeterminateRegions =
        checkLen < len && noCheck < len ? true : false;
    },
    //设置可点区域
    saveRegions() {
      let sel_regions = [],
        unchange_regions = [],
        selected = [];
      this.regionsList.map(item => {
        if (item.ost == item.st && item.st != 2) {
          unchange_regions.push(item.id);
        }
        if (item.ost != item.st && item.st == 1) {
          sel_regions.push(item.id);
        }
        if (item.st != 2) {
          selected.push(item.id);
        }
      });
      this.$api.BMS.station
        .requestStationSaveWaiterRegions({
          station_ids: this.multipleSelection,
          sel_regions,
          unchange_regions
        })
        .then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.weik();
            this.demand();
            this.regionsList = [];
            this.editRegions = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 可点区域选择全选或取消
    handleCheckAllRegionsChange(val) {
      this.regionsList.map(item => {
        item.c = val;
        item.st = val ? 1 : 2;
      });
      this.checkAllRegions = val;
      this.isIndeterminateRegions = false;
    },
    //点击设置系统角色按钮
    toEditSysPrivs() {
      if (this.multipleSelection.length > 0) {
        this.deptIds = [];
        this.$api.BMS.station
          .requestStationSysPrivs({
            station_ids: this.multipleSelection
          })
          .then(res => {
            if (res.code == 1) {
              res.data.map(item => {
                item.ost = item.st;
                item.c = item.st == 1 ? true : false;
              });
              this.sysPrivsList = res.data || [];
              this.editSysPrivs = true;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    //监测设置系统角色数据变化
    sysPrivsChange(val, item) {
      this.sysPrivsList.map(v => {
        if (v.id == item.id) {
          v.c = val;
          v.st = val ? 1 : 2;
        }
      });
    },
    //设置登录权限
    saveSysPrivs() {
      this.$api.BMS.station
        .requestStationSaveSysPrivs({
          station_ids: this.multipleSelection,
          sel_auth_modes: this.sysPrivsList.filter(item => item.st == 1).map(item => item.id * 1), //[]int64   选中的系统权限列表
          unchange_auth_modes: this.sysPrivsList.filter(item => item.st == 3).map(item => item.id * 1),// []int64   部分选中的系统权限列表(就是没有修改的部分选中的列表)
        })
        .then(res => {
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.weik();
            this.demand();
            this.sysPrivsList = [];
            this.editSysPrivs = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 为空
    weik() {
      this.multipleSelection = [];
      this.isIndeterminate = false;
      this.checkAll = false;
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var s = i - 48 - 60 - 55 - 37 - 60;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
      });
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      if (val) {
        this.multipleSelection = [];
        for (const key in this.tableData) {
          this.multipleSelection.push(this.tableData[key].id);
        }
      } else {
        this.multipleSelection = [];
      }
      this.isIndeterminate = false;
    },
    // 控制单个选中
    handleCheckedCitiesChange(value) {
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.tableData.length;
    },
    // 获取岗位信息内容 标记
    demand() {
      this.$api.BMS.station.requestStationList().then(res => {
        console.log(res);
        if (res.code == 1) {
          let tableDataObj = {};
          res.data.map(item => {
            tableDataObj[item.id] = item.n;
          });
          this.tableData = res.data || [];
          this.tableDataObj = tableDataObj;
          //显示标记
          this.quantity = [];
          for (const key in res.data) {
            if (this.quantity.length == 0) {
              this.quantity = [res.data[key].d == 1];
            } else {
              this.quantity.push(res.data[key].d == 1);
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 点开创建name为空
    xingh() {
      this.form_rule_msg_name = "";
      this.dialogFormVisible = true;
      this.stationName = "";
      this.title = true;
    },
    // 创建岗位
    construction() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      if (this.stationName == "") {
        this.$message.warning("必选框不能为空");
      } else {
        this.$api.BMS.station
          .requestStationNew({
            name: this.stationName
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "新增成功",
                type: "success"
              });
              this.demand();
              this.dialogFormVisible = false;
              this.stationName = "";
              this.bempty();
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 编辑内容
    compileprinter() {
      if (this.multipleSelection.length == 1) {
        this.form_rule_msg_name = "";
        this.stationName = this.tableDataObj[this.multipleSelection[0]];
        this.dialogFormVisible = true;
        this.title = false;
      } else {
        this.$message({
          message: "请选择一个进行编辑",
          type: "warning"
        });
      }
    },
    // 保存编辑内容
    saveprinter() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_name) return;
      this.$api.BMS.station
        .requestStationSave({
          id: this.multipleSelection[0],
          n: this.stationName
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.demand();
            this.stationName = "";
            this.dialogFormVisible = false;
            this.bempty();
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 重试
    chdefrs() {
      if (this.srnr == "置为无效") {
        this.noneffective();
      } else if (this.srnr == "置为有效") {
        this.effective();
      } else if (this.srnr == "批量删除") {
        this.printerdel();
      }
    },
    // 同步
    synchronizon() {
      this.kzsfjy = true;
      var s = "";
      if (this.srnr == "置为无效") {
        s = 2;
      } else if (this.srnr == "置为有效") {
        s = 1;
      } else if (this.srnr == "批量删除") {
        s = 3;
      }
      var tid = [];
      var id = [];
      for (const iterator of this.cwsm.cs) {
        tid.push(iterator.tid);
        id.push(iterator.id);
      }
      console.log(tid, id, s);
      this.$api.ERP.station
        .requestStationOb({
          op_status: Number(s),
          type_ids: tid,
          ids: id
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            for (const key in this.cwsm.cs) {
              this.cwsm.cs[key].jg = "成功";
            }
            this.refresh(this.$route.params.id);
            if (this.cwsm.ns.length < 1) {
              this.chdefrs();
            }
          } else if (res.code == 2) {
            for (const key in this.cwsm.cs) {
              for (const keys in res.data) {
                if (this.cwsm.cs[key].id == res.data[keys].id) {
                  this.cwsm.cs[key].jg = "失败";
                }
              }
            }
            for (const key in this.cwsm.cs) {
              if (this.cwsm.cs[key].jg == "---") {
                this.cwsm.cs[key].jg = "成功";
              }
            }
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 无效
    noneffective() {
      this.$api.BMS.station
        .requestStationDisable({ ids: this.multipleSelection })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.demand();
            this.dialogFible = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.bempty();
          } else if (res.code == 2) {
            this.dialogFible = true;
            this.kzsfjy = false;
            this.srnr = "置为无效";
            this.cwsm.ns = res.data.ns || [];
            for (const key in res.data.cs) {
              res.data.cs[key].jg = "---";
            }
            this.cwsm.cs = res.data.cs || [];
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 有效
    effective() {
      this.$api.BMS.station
        .requestStationEnable({ ids: this.multipleSelection })
        .then(res => {
          // console.log(res);
          if (res.code == 1) {
            this.demand();
            this.dialogFible = false;
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
            this.bempty();
          } else if (res.code == 2) {
            this.dialogFible = true;
            this.kzsfjy = false;
            this.srnr = "置为有效";
            this.cwsm.ns = res.data.ns || [];
            for (const key in res.data.cs) {
              res.data.cs[key].jg = "---";
            }
            this.cwsm.cs = res.data.cs || [];
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 删除
    printerdel() {
      if (this.multipleSelection.length > 0) {
        this.$api.BMS.station
          .requestStationDel({ ids: this.multipleSelection })
          .then(res => {
            if (res.code == 1) {
              this.demand();
              this.dialogFible = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.bempty();
            } else if (res.code == 2) {
              this.dialogFible = true;
              this.kzsfjy = false;
              this.srnr = "批量删除";
              this.cwsm.ns = res.data.ns || [];
              for (const key in res.data.cs) {
                res.data.cs[key].jg = "---";
              }
              this.cwsm.cs = res.data.cs || [];
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "请先选择岗位",
          type: "warning"
        });
      }
    },
    // 为空
    bempty() {
      this.multipleSelection = [];
      this.isIndeterminate = false;
      this.checkAll = false;
    },

    // 设置权限
    async setAuthLimitHandle() {
      if (this.multipleSelection.length > 0) {
        const params = {
          station_ids: this.multipleSelection // []int64   角色Id列表
        };

        try {
          const res = await this.$api.BMS.station.reqGetAuthLimitConfig(params);
          if (res.code == 1) {
            res.data = res.data || [];
            this.authLimitInfo.authLimitArr = res.data.map(item => ({
              ...item,
              checked: item.st == 1,
              indeterminate: item.st == 3
            }));
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("获取权限列表失败", error);
        }
        this.authLimitInfo.show = true;
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },

    // 保存配置权限
    async saveAuthLimitHandle() {
      const params = {
        station_ids: this.multipleSelection, // []int64    角色Id列表
        sel_privs: this.authLimitInfo.authLimitArr
          .filter(item => item.checked)
          .map(item => item.id * 1), //  []int64   选中的权限Id列表
        unchange_privs: this.authLimitInfo.authLimitArr
          .filter(item => item.indeterminate)
          .map(item => item.id * 1) //[]int64   部分选中的权限Id列表(就是没有修改的部分选中的列表)
      };

      try {
        const res = await this.$api.BMS.station.reqSetAuthLimitConfig(params);
        if (res.code == 1) {
          this.$message.success("配置成功");
          this.authLimitInfo.show = false;
          this.multipleSelection = [];
          this.checkAll = false;
          this.isIndeterminate = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("保存权限设置失败", error);
      }
    },

    // 设置查单权限
    async setLookOrderHandle() {
      if(this.multipleSelection.length != 1) return this.$message.warning('请选择一个岗位进行查单权限配置')
      const params = {
        station_id: this.multipleSelection[0] * 1, // int64   待配置岗位Id
      }
      try {
        const res = await this.$api.BMS.station.reqGetLookOrderConfig(params)
        if (res.code == 1) {
          res.data.regions = res.data.regions || []
          this.lookOrderInfo.all.checkAll = res.data.full_check == 1
          this.lookOrderInfo.item.checkAll = res.data.regions.every(item => item.s == 1)
          this.lookOrderInfo.item.indeterminate = !this.lookOrderInfo.item.checkAll && res.data.regions.some(item => item.s == 1)
          this.lookOrderInfo.areaList = res.data.regions.map( item => ({
            ...item,
            checked: item.s == 1
          }))
          this.lookOrderInfo.show = true
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('服务员查单信息获取失败', error)
      }
    },

    lookOrderCheckBoxChange(type) {
      switch (type) {
        case 'allArea': // 全场可查看
          this.lookOrderInfo.item.checkAll = false
          this.lookOrderInfo.item.indeterminate = false
          this.lookOrderInfo.areaList = this.lookOrderInfo.areaList.map(item => ({
            ...item,
            checked: false
          }))
          break
        case 'all': // 全选
          this.lookOrderInfo.all.checkAll = false
          this.lookOrderInfo.item.indeterminate = false
          this.lookOrderInfo.areaList = this.lookOrderInfo.areaList.map( item => ({
            ...item,
            checked: this.lookOrderInfo.item.checkAll
          }))
          break
        case 'item': // 单选
          this.lookOrderInfo.all.checkAll = false
          this.lookOrderInfo.item.checkAll = this.lookOrderInfo.areaList.every(item => item.checked)
          this.lookOrderInfo.item.indeterminate = !this.lookOrderInfo.item.checkAll && this.lookOrderInfo.areaList.some(item => item.checked)
          break
      }
    },
    // 提交查单权限区域
    async submitLookOrderAreaHandle(){
      let typeId = ''
      if (this.lookOrderInfo.all.checkAll) typeId = 1
      else if (this.lookOrderInfo.item.checkAll || this.lookOrderInfo.item.indeterminate) typeId = 2
      else typeId = 3

      const params = {
        station_id: this.multipleSelection[0] * 1, // int64    岗位Id
        type_id: typeId, //  int    类型 1 全场查单 2 区域查单 3 无查单(删除查单权限)
        // region_ids: typeId == 2 ? this.lookOrderInfo.areaList.filter(item => item.checked).map(item => item.id * 1) : '', // []int64   针对type_id=2区域查单, 对应可查单区域列表, 其他情况下传空
      }

      if(typeId == 2) params.region_ids = this.lookOrderInfo.areaList.filter(item => item.checked).map(item => item.id * 1)

      try {
        const res = await this.$api.BMS.station.reqSetLookOrderConfig(params)
        if (res.code == 1) {
          this.$message.success('设置成功')
          this.lookOrderInfo.show = false
          this.weik();
          this.demand();
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('查单权限设置失败', error)
      }
    }
  },
  filters: {
    pand: function(v) {
      if (v == "置为无效") {
        return "无效";
      } else if (v == "置为有效") {
        return "有效";
      } else if (v == "批量删除") {
        return "删除";
      }
    }
  },
  watch: {
    windowHeigh(val) {
      let that = this;
      this.RollMaxHeight(val);
      //   console.log("实时屏幕高度：",val, that.windowHeigh );
    },
    windowWidt(val) {
      let that = this;
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    salesFreeLimitsDatas: {
      handler() {
        this.getSalesFreePrdList()
      },
      deep: true,
      immediate: true
    }
  }
};
</script>
<style>
/* 靠右 */
.station .el-dialog {
  margin: 0px 0px 0px auto !important;
  background-color: #f9f9f9;
  height: 100%;
  position: relative;
}

.station .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.station .el-dialog__body {
  padding: 0px 0px 30px 20px;
  overflow-y: scroll !important;
  /* width: 100%; */
  width: calc(100% - 20px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.station .el-dialog {
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.station {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

/* 必填 */
.station .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
}

.station .controlling {
  color: #40404e;
  width: 230px !important;
}

.station .reqfieldsd {
  font-size: 14px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 表格无数据时展示 */
.station .tiaodd {
  position: sticky;
  left: 0;
  top: 44px;
  width: 100% !important;
  display: inline-block;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.station .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0;
}

.station .nodata img {
  width: 60px;
  height: 60px;
}

.station .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

/* 改限制字体数量的颜色背景 */
.station .el-input .el-input__count .el-input__count-inner {
  background: none;
  color: #40404e;
}

.station .el-input__suffix {
  background-color: #1a1a20;
  color: #40404e;
  right: -45px;
  /* height: 20px; */
  top: 8px;
  /* line-height: 20px; */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.station .compatibility {
  display: flex;
  align-items: center;
  margin-bottom: 10px;
}

.station-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.station-controller {
  /*margin-top: 30px;*/
  min-height: 54px;
  background-color: #eee;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.station .dialogFormVisible .el-dialog {
  width: 550px !important;
}

.station .editSysPrivs .el-dialog {
  width: 700px !important;
}

.station .editCates .el-dialog {
  width: 600px !important;
}

.station .editCatesOther .el-dialog {
  width: 850px !important;
}

.station .editWaiterCates .el-dialog {
  width: 600px !important;
}

.station .editStoreAdmins .el-dialog {
  width: 600px !important;
}

.station .editStoreAdmins .mandatory {
  min-width: 150px;
}

.station .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.station .el-dialog {
  background-color: #f9f9f9;
}

.station .el-dialog__header,
.station .el-dialog__footer {
  background-color: #1a1a21;
}

.station .el-dialog__title,
.station .el-dialog__headerbtn .el-dialog__close,
.station .el-form-item__label {
  color: #1a1a21;
}

.station .el-checkbox__input {
  background-color: transparent;
}

.station .el-dialog {
  width: 30vw;
}

/* 改变多选框背景颜色和上下间距 */
.station .el-checkbox-group {
  display: flex;
  align-items: flex-end;
  justify-content: flex-start;
}

.station .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

/* 列表 */
.zsykd {
  width: 100%;
  overflow-x: scroll !important;
}

.station .zhuixiaoi {
  width: 100%;
  border-collapse: collapse;
  color: #40404e;
}

.station .zhuixiaoi .mmodity tr th {
  min-height: 36px;
  box-sizing: border-box;
  text-align: left;
  font-size: 14px;
  font-weight: 600;
  padding: 8px 0 4px 20px;
  color: #40404e;
}
.station .zhuixiaoi .mmodity tr th .el-checkbox__label {
  font-size: 14px;
  font-weight: 600;
}

.station .zhuixiaoi .limiting .drag-list td {
  min-height: 36px;
  box-sizing: border-box;
  text-align: left;
  font-size: 14px;
  font-weight: 400;
  padding: 8px 0 4px 20px;
}

.station .zhuixiaoi .limiting .drag-list {
  display: block;
  display: flex;
}

.station .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.station .zhuixiaoi .mmodity tr {
  background-color: #f5f5f5;
  display: flex;
}

.station .zhuixiaoi .limiting {
  overflow-y: auto !important;
  max-height: 540px;
  display: block;
}

.station .drag-list td:nth-of-type(1),
.station .mmodity th:nth-of-type(1) {
  width: 70px;
}

.station .mmodity th:nth-of-type(2),
.station .drag-list td:nth-of-type(2) {
  width: 150px;
}

.station .mmodity th:nth-of-type(3),
.station .drag-list td:nth-of-type(3) {
  width: 350px;
}

.station .drag-list td:nth-of-type(4),
.station .mmodity th:nth-of-type(4) {
  width: 140px;
}

.station .drag-list td:nth-of-type(5),
.station .mmodity th:nth-of-type(5) {
  width: 60px;
}

.station .drag-list td:nth-of-type(6),
.station .mmodity th:nth-of-type(6) {
  width: 140px;
}

.station .drag-list td:nth-of-type(7),
.station .mmodity th:nth-of-type(7) {
  width: 140px;
}

.station .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.station .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

.editCatesOtherTable .drag-list td:nth-of-type(1),
.editCatesOtherTable .mmodity th:nth-of-type(1) {
  width: 50px;
}

.editCatesOtherTable .mmodity th:nth-of-type(2),
.editCatesOtherTable .drag-list td:nth-of-type(2) {
  width: 140px;
}

.editCatesOtherTable .drag-list td:nth-of-type(3),
.editCatesOtherTable .mmodity th:nth-of-type(3) {
  width: 60px;
}

.editCatesOtherTable .drag-list td:nth-of-type(4),
.editCatesOtherTable .mmodity th:nth-of-type(4) {
  width: 60px;
}

.editCatesOtherTable .drag-list td:nth-of-type(5),
.editCatesOtherTable .mmodity th:nth-of-type(5) {
  width: 60px;
}

.editCatesOtherTable .drag-list td:nth-of-type(6),
.editCatesOtherTable .mmodity th:nth-of-type(6) {
  width: 60px;
}

.editCatesOtherTable .drag-list td:nth-of-type(7),
.editCatesOtherTable .mmodity th:nth-of-type(7) {
  width: 60px;
}

.editCatesOtherTable .drag-list td:nth-of-type(8),
.editCatesOtherTable .mmodity th:nth-of-type(8) {
  width: 150px;
}

/* 全选颜色 */
.station .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

.station .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

/* 错误2 */
.station .diagrgeesfelogFor .el-dialog {
  width: 720px;
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.station .diagrgeesfelogFor .wwent {
  color: #ce4153;
  font-size: 14px;
  margin: 20px 0px 20px 20px;
  display: flex;
  align-items: center;
}

.station .diagrgeesfelogFor .wentlb {
  margin-left: 20px;
  width: 640px;
}

.station .diagrgeesfelogFor .zhuixiaoi {
  width: 100%;
}

.station .diagrgeesfelogFor .zhuixiaoi .limiting {
  max-height: 280px !important;
  overflow-y: auto !important;
}

.station .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(1),
.station .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(1) {
  width: 50px;
}

.station .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(2),
.station .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(2) {
  width: 320px;
}

.station .diagrgeesfelogFor .wentlb .mmodity th:nth-of-type(3),
.station .diagrgeesfelogFor .wentlb .drag-list td:nth-of-type(3) {
  width: 200px;
}

.station .diagrgeesfelogFor .danykz .mmodity th:nth-of-type(2),
.station .diagrgeesfelogFor .danykz .drag-list td:nth-of-type(2) {
  width: 520px;
}

/* 无效颜色 */
.station .diagrgeesfelogFor .el-button--primary.is-disabled,
.station .diagrgeesfelogFor .el-button--primary.is-disabled:hover {
  background-color: #1f2846;
  color: #4e505a;
  border-color: #1f2846;
}

.sys_privs_check {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
}

.sys_privs_check .el-checkbox {
  margin: 5px 15px 5px 0;
}

.station .mandatory {
  min-width: 110px;
}

.sys_privs_info {
  font-size: 14px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  margin-left: 40px;
  line-height: 20px;
}

.regions_check {
  display: flex;
  flex-direction: column;
  flex-wrap: wrap;
}

.mandatory_editCates,
.regions_mandatory,
.mandatory_editWaiterCates {
  line-height: 24px;
}

.storeAdmins_mandatory {
  line-height: 28px;
}

.station .compatibility_editCates,
.station .regions_compatibility,
.station .storeAdmins_compatibility,
.station .compatibility_editWaiterCates {
  align-items: flex-start;
}

.regions_check .el-checkbox {
  margin: 2px 25px;
}

.regions_check .el-checkbox:nth-child(1) {
  margin: 2px 0;
}

.tab-header {
  height: 50px;
  width: 100%;
  padding: 0 20px;
  box-sizing: border-box;
}

.tab-item {
  height: 100%;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: flex-start;
}

.tab-item-title {
  width: 100px;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #40404e;
  box-sizing: border-box;
  font-weight: 400;
  cursor: pointer;
}

.tab-item-title-active {
  font-weight: 500;
  border-bottom: 3px solid #2170ff;
  color: #2170ff !important;
}

.drag-list-check {
  /* background: rgba(39, 52, 82, .5) !important; */
}
</style>

