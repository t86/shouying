<template>
  <div class="sin">
    <div class="sin-rkrq">
      <div class="rkrq">
        <span class>入库日期：</span>
        <el-radio-group v-model="jindst" class="danxk">
          <el-radio-button label="1">
            <img v-show="jindst != 1" src="@/assets/img/日期标签-灰.png" alt />
            <img v-show="jindst == 1" src="@/assets/img/日期标签-选中.png" alt />
            近七天
          </el-radio-button>
          <el-radio-button label="2">
            <img v-show="jindst != 2" src="@/assets/img/日期标签-灰.png" alt />
            <img v-show="jindst == 2" src="@/assets/img/日期标签-选中.png" alt />
            近1个月
          </el-radio-button>
          <el-radio-button label="3">
            <img v-show="jindst != 3" src="@/assets/img/日期标签-灰.png" alt />
            <img v-show="jindst == 3" src="@/assets/img/日期标签-选中.png" alt />
            近3个月
          </el-radio-button>
        </el-radio-group>
        <el-date-picker
          v-model="Inbound.date"
          type="daterange"
          :editable="false"
          :unlink-panels="true"
          @input="adgg"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          format="yyyy-MM-dd"
          value-format="yyyy-MM-dd"
        ></el-date-picker>
      </div>
      <div class="rkrq">
        <span>入库类型：</span>
        <el-select v-model="Inbound.type" @change="inquirequery" placeholder="全部" clearable>
          <el-option label="全部" value></el-option>
          <el-option label="采购入库" :value="1"></el-option>
          <el-option label="其他入库" :value="7"></el-option>
          <el-option label="盘盈入库" :value="51"></el-option>
        </el-select>
      </div>
      <div class="rkrq">
        <span>备注：</span>
        <el-input v-model="Inbound.remark" @input="inquirequery" placeholder="请输入备注模糊搜索"></el-input>
      </div>
      <div class="rkrq">
        <!-- <el-button type="primary" @click="inquirequery">查询</el-button> -->
        <el-button type="primary" @click="resetstorage">重置</el-button>
      </div>
    </div>

    <div class="sin-controller">
      <icon-button @click.native="xingh" text="新增" img="添加.png" colors="#f5f5f5"></icon-button>
      <characters-button @click.native="compileprinter" colors="#f5f5f5" wz="红冲"></characters-button>
      <characters-button @click.native="noneffective" colors="#f5f5f5" wz="红冲整单"></characters-button>
      <characters-button @click.native="effective" colors="#f5f5f5" wz="类似创建"></characters-button>
    </div>
    <div style="position: relative">
      <div style="display: inline-block;" class="zsykd">
        <table class="zhuixiaoi">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >全选</el-checkbox>
              </th>
              <th>单号</th>
              <th>入库类型</th>
              <th>入库仓库</th>
              <th>发票类型</th>
              <th>
                <div class="alignment">入库总额</div>
              </th>
              <th>备注</th>
              <th>入库时间</th>
              <th>入库操作人</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            ref="systemForm"
            @scroll="sysHandleScroll()"
            @mouseover="changeFlag(false)"
            :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>13?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }"
          >
            <tr
              v-for="(item,i) in tableData"
              :key="item.id"
              class="drag-list"
              :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
            >
              <td>
                <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                  <el-checkbox :disabled="item.hc==2" :label="item.id">{{i+1}}&emsp;&thinsp;</el-checkbox>
                </el-checkbox-group>
              </td>
              <td>
                <div class="ewdetai" @click="showviewdetails(item.id)">{{item.cd}}</div>
              </td>
              <td>{{item.rt}}</td>
              <!-- <td>{{item.sn}}</td> -->
              <td>
                <ellipsis-tooltip :text="item.sn || '-----'"></ellipsis-tooltip>
              </td>
              <td>{{item.f}}</td>
              <td>
                <div class="alignment">{{item.ta}}</div>
              </td>
              <td>
                <ellipsis-tooltip :text="item.r || '-----'"></ellipsis-tooltip>
              </td>
              <td>{{item.st}}</td>
              <td>{{item.en}}</td>
            </tr>
          </tbody>
        </table>
        <div class="tiaodd" v-if="tableData.length<1">
          <td class="nodata" :style="{'height':`${MaxHeight}px !important`}">
            <img src="../../../../assets/img/wu.png" alt />
            <div class="hint">暂无数据</div>
          </td>
        </div>
      </div>
      <div
        style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;"
      >
        <table class="zhuixiaoi zhuixiaoi_l" style="width: auto;">
          <thead class="mmodity">
            <tr>
              <th>
                <el-checkbox
                  :indeterminate="isIndeterminate"
                  v-model="checkAll"
                  @change="handleCheckAllChange"
                >全选</el-checkbox>
              </th>
              <th>单号</th>
              <th>入库类型</th>
              <th>入库仓库</th>
            </tr>
          </thead>
          <tbody
            class="limiting"
            ref="externalForm"
            @scroll="exterHandleScroll()"
            @mouseover="changeFlag(true)"
            :style="{'border-bottom':tableData.length<1?'0px':'',
                'width':tableData.length>13?'calc(100% + 6px)':'100%',
                'max-height':`${MaxHeight}px`
                }"
          >
            <tr
              v-for="(item,i) in tableData"
              :key="item.id"
              class="drag-list"
              :class="multipleSelection.includes(item.id)? 'drag-list-check':''"
            >
              <td>
                <el-checkbox-group v-model="multipleSelection" @change="handleCheckedCitiesChange">
                  <el-checkbox :disabled="item.hc==2" :label="item.id">{{i+1}}&emsp;&thinsp;</el-checkbox>
                </el-checkbox-group>
              </td>
              <td>
                <div class="ewdetai" @click="showviewdetails(item.id)">{{item.cd}}</div>
              </td>
              <td>{{item.rt}}</td>
              <!-- <td>{{item.sn}}</td> -->
              <td>
                <ellipsis-tooltip :text="item.sn || '-----'"></ellipsis-tooltip>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="Pagination">
      <el-pagination
        background
        layout="prev, pager, next"
        @current-change="handleCurrentChange"
        :page-size="10"
        :total="Inbound.rowcnt"
      ></el-pagination>
    </div>

    <!-- 新增入库 -->
    <div v-show="dialogFormVisible" class="dialogFormVisible">
      <el-dialog
        title="新增入库"
        :visible.sync="dialogFormVisible"
        @close="dialogFormVisible = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="tidsesfe">
            <div class="compatibility compatibils">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>入库仓库：
              </div>
              <el-select
                v-model="ProductLibrary.warehouse"
                placeholder="请选择仓库"
                class="controlling"
                clearable
              >
                <el-option
                  v-for="(each,i) in ProductLibrary.warehousess"
                  :key="i"
                  :label="each.n"
                  :value="each.id"
                ></el-option>
              </el-select>
            </div>
            <div class="compatibility compatibils">
              &emsp;&emsp;&emsp;
              <div class="mandatory">
                <span class="reqfieldsd">*</span>入库类型：
              </div>
              <el-select
                v-model="ProductLibrary.type"
                placeholder="请选择类型"
                class="controlling"
                clearable
              >
                <el-option label="采购入库" :value="1"></el-option>
                <el-option label="其他入库" :value="7"></el-option>
              </el-select>
            </div>
          </div>
          <div class="compatibil" layout="row">
            <div class="compatibility compatibils">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>发票类型：
              </div>
              <el-select
                v-model="ProductLibrary.tickVal"
                placeholder="请选择发票类型"
                class="controlling"
              >
                <el-option
                  v-for="(each,i) in ProductLibrary.ticketOption"
                  :key="i"
                  :label="each.n"
                  :value="each.id"
                ></el-option>
              </el-select>
            </div>
            <div class="compatibility compatibils" style="margin-left: 44px;" v-show="ProductLibrary.type != 7">
              <div class="mandatory">
                <span class="reqfieldsd">*</span>供应商：
              </div>
              <el-select
                v-model="ProductLibrary.supplier"
                placeholder="请选择供应商"
                class="controlling"
              >
                <el-option
                  v-for="(each,i) in ProductLibrary.supplierss"
                  :key="i"
                  :label="each.n"
                  :value="each.id"
                ></el-option>
              </el-select>
            </div>
          </div>
          <div class="compatibility compatibils">
            <div class="mandatory">
              <span class="reqfieldsd"></span>备注：
            </div>
            <el-input
              type="textarea"
              v-model="ProductLibrary.remark"
              :rows="3"
              placeholder="请输入备注"
              class="controlling"
              show-word-limit
              :class="form_rule_msg_remark?'error':''"
              @blur="validator('remark')"
            />
            <div class="cwts">{{form_rule_msg_remark}}</div>
          </div>
        </el-form>
        <div class="addmaterial">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th></th>
                <th>物料名称</th>
                <th>一级分类</th>
                <th>二级分类</th>
                <th>单位</th>
                <th>
                  <div class="alignment">入库数量</div>
                </th>
                <th>
                  <div class="alignment">入库单价</div>
                </th>
                <th>
                  <div class="alignment">入库小计</div>
                </th>
                <th>
                  <div v-if="ProductLibrary.tickVal == 2" class="alignment">入库小计(裸价)</div>
                </th>
              </tr>
            </thead>
            <tbody
              class="limiting"
              :style="{'border-bottom':supplies.length<1?'0px':'',
                            'width':supplies.length>8?'calc(100% + 6px)':'100%'}"
            >
              <tr v-for="(item,i) in supplies" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td layout="row" layout-align="start center">
                  <icon-button
                    style="width:20px;height:20px;cursor:pointer"
                    @click.native="appendmaterial"
                    text="新增"
                    img="添加.png"
                    colors="#f5f5f5"
                  ></icon-button>
                  <icon-button
                    style="width:20px;height:20px;cursor:pointer"
                    @click.native="batchDeleteSupplies(item.id)"
                    text="删除"
                    img="删除.png"
                    colors="#6B2830"
                    bjcolors="#491E24"
                  ></icon-button>
                </td>
                <td>
                  <el-select
                    v-model="item.name"
                    filterable
                    remote
                    reserve-keyword
                    placeholder="请输入物料拼音首字母或名称的关键字"
                    :remote-method="remoteMethod"
                    ref="selectsse"
                    class="topwidth"
                    :loading="loading"
                    @change="changeNameHandle(item)"
                  >
                    <el-option
                      v-for="items in dimoptions"
                      :key="items.id"
                      :label="items.n"
                      :value="items.id"
                    ></el-option>
                  </el-select>
                </td>
                <td>{{item.classifyyi}}</td>
                <td>{{item.classifyer}}</td>
                <td>{{item.unit}}</td>
                <td>
                  <el-input
                    v-model="item.quantity"
                    type="number"
                    min="1"
                    placeholder="请输入入库数量"
                    class="Writmiddle"
                  />
                </td>
                <td style="text-align:right">{{ProductLibrary.tickVal==2?(item.amt / 1.13 / item.quantity).toFixed(4):(item.amt / item.quantity).toFixed(4)}}</td>
                <td v-if="ProductLibrary.tickVal==2" style="text-align:right">{{(item.amt/1.13).toFixed(4)}}</td>
                <td>
                  <el-input
                    v-model="item.amt"
                    type="number"
                    :placeholder="ProductLibrary.tickVal == 2 ?'请输入入库小计(裸价)':'请输入入库小计'"
                    class="Writmiddle"
                  />
                </td>
              </tr>
            </tbody>
          </table>
          <div class="tiaodd" v-if="supplies.length<1">
            <td class="nodata">
              <img src="../../../../assets/img/wu.png" alt />
              <div class="hint">暂无数据</div>
            </td>
          </div>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogFormVisible = false">取消</el-button>
          <el-button type="primary" @click="construction">确认</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 查看详情 -->
    <div v-show="cfdetails" class="viewdetailscls">
      <el-dialog
        title="查看详情"
        :visible.sync="cfdetails"
        @close="cfdetails = false"
        :close-on-click-modal="false"
      >
        <div ref="print" class="print" id="print">
          <div class="printsin">
            <div class="monad">其他入库单</div>
            <div class="form m-t-6" style="background: #eee;border-radius:10px">
              <div class="row" layout="row" layout-align="start center">
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">单号：</div>
                  <div class="value" style="width:150px">{{viewdetails.code}}</div>
                </div>
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">仓库：</div>
                  <div class="value" style="width:150px">{{viewdetails.store_name}}</div>
                </div>
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">类型：</div>
                  <div class="value" style="width:150px">{{viewdetails.record_type}}</div>
                </div>
              </div>
              <div class="row" layout="row" layout-align="start center">
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">入库时间：</div>
                  <div class="value" style="width:150px">{{viewdetails.store_time}}</div>
                </div>
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">入库操作员名称：</div>
                  <div class="value" style="width:150px">{{viewdetails.oper_emp_name}}</div>
                </div>
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">入库单总金额：</div>
                  <div class="value" style="width:150px">{{viewdetails.total_amt}}</div>
                </div>
              </div>
              <div class="row" layout="row" layout-align="start center">
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">供应商：</div>
                  <div class="value" style="width:150px">{{viewdetails.supplier_name}}</div>
                </div>
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">发票类型：</div>
                  <div class="value" style="width:150px">{{viewdetails.fapiao_type}}</div>
                </div>
                <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                  <div class="label" style="width:150px;text-align:right">备注：</div>
                  <div class="value" style="width:150px">{{viewdetails.remark || '---'}}</div>
                </div>
              </div>
            </div>
            <!-- <el-form label-position="left">
              <div class="tidsesfe">
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>单号：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.code}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>仓库：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.store_name}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>类型：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.record_type}}</div>
                </div>
              </div>
              <div class="tidsesfe">
                <div class="compatibil">
                  <div class="compatibility">
                    <div class="mandatory">
                      <span class="reqfieldsd"></span>入库时间：
                    </div>
                    <div class="materialnr controlling">{{viewdetails.store_time}}</div>
                  </div>
                </div>
                <div class="compatibil">
                  <div class="compatibility">
                    <div class="mandatory">
                      <span class="reqfieldsd"></span>入库操作员名称：
                    </div>
                    <div class="materialnr controlling">{{viewdetails.oper_emp_name}}</div>
                  </div>
                </div>
                <div class="compatibil">
                  <div class="compatibility">
                    <div class="mandatory">
                      <span class="reqfieldsd"></span>入库单总金额：
                    </div>
                    <div class="materialnr controlling">{{viewdetails.total_amt}}</div>
                  </div>
                </div>
              </div>
              <div class="tidsesfe">
                <div class="compatibil">
                  <div class="compatibility">
                    <div class="mandatory">
                      <span class="reqfieldsd"></span>供应商：
                    </div>
                    <div class="materialnr controlling">{{viewdetails.supplier_name || '----'}}</div>
                  </div>
                </div>
                <div class="compatibil">
                  <div class="compatibility">
                    <div class="mandatory">
                      <span class="reqfieldsd"></span>发票类型：
                    </div>
                    <div class="materialnr controlling">{{viewdetails.fapiao_type || '----'}}</div>
                  </div>
                </div>
              </div>
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>备注：
                </div>
                <div class="materialnr gaib">{{viewdetails.remark || '---'}}</div>
              </div>
            </el-form> -->
            <div class="lbds m-t-8 m-b-3" v-if="viewdetails.dtls">明细单列表：</div>
            <div class="addmaterial" v-if="viewdetails.dtls">
              <table class="zhuixiaoi" border style="width:auto">
                <thead class="mmodity">
                  <tr>
                    <th>序号</th>
                    <th>物料名称</th>
                    <th>一级分类</th>
                    <th>二级分类</th>
                    <th>入库单位</th>
                    <th>入库数量</th>
                    <th>入库单价</th>
                    <th>入库小计</th>
                    <th v-if="viewdetails.fapiao_type == '专票'">原始裸价</th>
                  </tr>
                </thead>
                <tbody class="limiting">
                  <tr v-for="(item,i) in viewdetails.dtls" :key="i" class="drag-list">
                    <td>{{i+1}}</td>
                    <td>{{item.n || '-----'}}</td>
                    <td>{{item.moc || '-----'}}</td>
                    <td>{{item.mtc || '-----'}}</td>
                    <td>{{item.un || '----'}}</td>
                    <td>{{item.c}}</td>
                    <td>{{(item.a/item.c).toFixed(2)}}</td>
                    <td v-if="viewdetails.fapiao_type == '专票'">{{item.a}}</td>
                    <td>{{item.sa}}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="lbds"
              v-if="viewdetails.hc_dtls"
              style="margin-top: 16px;margin-bottom: 20px;"
            >红冲操作单列表：</div>
            <div class="addmatssial" v-if="viewdetails.hc_dtls">
              <table class="zhuixiaoi" border style="width:auto">
                <thead class="mmodity">
                  <tr>
                    <th>序号</th>
                    <th>物料名称</th>
                    <th>物料操作员名称</th>
                    <th>红冲数量</th>
                    <th>红冲金额</th>
                    <th>红冲单位</th>
                    <th>红冲前数量</th>
                    <th>红冲后数量</th>
                    <th>红冲操作时间</th>
                  </tr>
                </thead>
                <tbody class="limiting">
                  <tr v-for="(item,i) in viewdetails.hc_dtls" :key="i" class="drag-list">
                    <td>{{i+1}}</td>
                    <td>{{item.n}}</td>
                    <td>{{item.oen}}</td>
                    <td>{{item.c}}</td>
                    <td>{{item.a}}</td>
                    <td>{{item.un}}</td>
                    <td>{{item.bc}}</td>
                    <td>{{item.ac}}</td>
                    <td>{{item.ot}}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="signature show">
              <div>
                <span>总金额：{{viewdzj}}元</span>
              </div>
            </div>
            <div class="signature show">
              <div>
                <span>签收人：</span>
                <div class="xian"></div>
              </div>
              <div>
                <span>送货人：</span>
                <div class="xian"></div>
              </div>
            </div>
          </div>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="cfdetails = false">关闭</el-button>
          <el-button type="primary" v-show="viewdetails.status == '已完成'" v-print="print">打印</el-button>
          <el-button type="primary" @click="effective">类似创建</el-button>
          <el-button type="primary" v-show="viewdetails.status == '已完成'" @click="compileprinter">红冲</el-button>
          <el-button type="primary" v-show="viewdetails.status == '已完成'" @click="noneffective">红冲整单</el-button>
        </span>
      </el-dialog>
    </div>
    <!-- 红冲 -->
    <div v-show="Reddashed" class="hcwdetailscls" v-if="hcsl.length > 0">
      <el-dialog
        title="红冲"
        :visible.sync="Reddashed"
        @close="Reddashed = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory" style>
                <span class="reqfieldsd"></span>单号：
              </div>
              <div class="materialnr controlling">{{viewdetails.code}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>入库仓库：
              </div>
              <div class="materialnr controlling">{{viewdetails.store_name}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>入库类型：
              </div>
              <div class="materialnr controlling">{{viewdetails.record_type}}</div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>入库操作员名称：
                </div>
                <div class="materialnr controlling">{{viewdetails.oper_emp_name}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>入库单总金额：
                </div>
                <div class="materialnr controlling">{{viewdetails.total_amt}}</div>
              </div>
            </div>
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>供应商：
                </div>
                <div class="materialnr controlling">{{viewdetails.supplier_name || '----'}}</div>
              </div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibil">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd"></span>入库时间：
                </div>
                <div class="materialnr controlling">{{viewdetails.store_time}}</div>
              </div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>备注：
              </div>
              <div class="materialnr gaib">{{viewdetails.remark || '---'}}</div>
            </div>
          </div>
        </el-form>
        <div class="addmaterial">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>物料名称</th>
                <th>一级分类</th>
                <th>二级分类</th>
                <th>入库单位</th>
                <th>
                  <div class="alignment">入库数量</div>
                </th>
                <th>
                  <div class="alignment">入库单价</div>
                </th>
                <th>红冲实际入库数量</th>
                <th>
                  <div class="alignment">红冲后入库数量</div>
                </th>
                <th>
                  <div class="alignment">红冲小计</div>
                </th>
                <th>
                  <div class="alignment">实际入库小计</div>
                </th>
              </tr>
            </thead>
            <tbody class="limiting">
              <tr v-for="(item,i) in viewdetails.dtls" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item.n || '-----'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.moc || '-----'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.mtc || '-----'"></ellipsis-tooltip>
                </td>
                
                <td>
                  <ellipsis-tooltip :text="item.un || '----'"></ellipsis-tooltip>
                </td>
                <td>
                  <div class="alignment">{{item.c}}</div>
                </td>
                <td>
                  <div class="alignment">{{(item.a/item.c).toFixed(2)}}</div>
                </td>
                <td>
                  <el-input
                    v-model="hcsl[i].sl"
                    placeholder="请输入数量"
                    ref="selectsse"
                    class="Writmiddle"
                  />
                </td>
                <td>
                  <div class="alignment">{{item.c - (hcsl[i].sl || 0)}}</div>
                </td>
                <td>
                  <div class="alignment">{{((item.a/item.c)*hcsl[i].sl).toFixed(2)}}</div>
                </td>
                <td>
                  <div class="alignment">{{(item.a-(item.a/item.c)*hcsl[i].sl).toFixed(2)}}</div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="Reddashed = false">取消</el-button>
          <el-button type="primary" @click="hcaffirmReddashed">确认</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
<script>
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import IconButton from "@/components/IconButton.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      Inbound: {
        date: [], //日期
        type: "", //类型
        pagenum: 1, //第几页
        pagecnt: 1, //总页数
        rowcnt: 1, //总行数
        jlines: 5, //每页多少行
        remark: "" //备注
      }, //入库
      jindst: "1", //近多少天
      tableData: [], // 读取管理列表
      dialogFormVisible: false, //控制新建入库是否显示
      ProductLibrary: {
        warehousess: [], //入库仓库列表
        warehouse: "", //入库仓库
        type: "", // 入库类型
        supplierss: [], //供应商列表
        tickVal: '',
        ticketOption: [
          {
            n: '普票',
            id: 1
          },
          {
            n: '专票',
            id: 2
          }
        ],
        supplier: "", //供应商
        remark: "" //备注
      }, //入库
      multipleSelection: [], // 选中的内容
      isIndeterminate: false, // 仓库选择一部分
      checkAll: false, //仓库全选
      addprincipal: false, //控制添加物料是否显示
      dimoptions: [], // 模糊查询列表
      dimvalue: "", // 查询选中的
      loading: false, // 是否正在从远程获取数据

      materialnrs: {
        id: "", //物料id
        name: "", //名称
        classifyyi: "", //分类一级
        classifyer: "", //分类二级
        units: [], //单位列表
        unit: "", //单位
        amt: "", //价格
        quantity: "", //数量
        propertys: [] //属性列表
      }, // 物料信息内容
      totalprices: "", //总价
      materi: [], //选中属性列表
      supplies: [], //已添加的物料
      viewdetails: {}, //查看详情内容
      cfdetails: false, // 控制查看详情显示与否
      Reddashed: false, // 控制红冲显示与否
      hcsl: [], //红冲内容

      viewdzj: 0,

      print: {
        id: "print",
        popTitle: "其他入库单" // 打印配置页上方标题
        // extraHead: '调拨入库单',
      },
      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      form_rules: ["remark"],
      form_rule_msg_remark: "",

      flag: false
    };
  },
  filters: {
    decimal(v) {
      // console.log(v);
      return v.toFixed(2);
    },
    dwdaf(v) {
      // console.log(v);
      return v;
    }
  },
  mounted() {
    this.daterq();
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
  components: {
    EllipsisTooltip,
    IconButton,
    CharactersButton
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
        case "remark":
          if (this.$overall.character(this.ProductLibrary.remark) > 280) {
            this.form_rule_msg_remark = "输入文字长度超过140";
          } else {
            this.form_rule_msg_remark = "";
          }
          break;
      }
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var g = document.getElementsByClassName("sin-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 55 - 40 - 50 - g;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // 打印
    Print() {
      // this.$print(this.$refs.print)
      // console.log(this.$prints);
      this.$Print(this.$refs.print, { "no-print": ".className" });
      // window.print()
      myPrint(this.$refs.print);
      function myPrint(obj) {
        //    var newWindow=window.open("打印窗口","_blank");
        //    var docStr = obj.innerHTML;
        //    newWindow.document.write(docStr);
        //    newWindow.document.close();
        newWindow.print();
        //    newWindow.close();
      }
    },
    // 使用自定义日期后取消单选框选择的
    adgg(i) {
      console.log(i);
      this.jindst = "";
      this.demand();
    },
    // 日期
    daterq() {
      var now = new Date();
      var year = now.getFullYear(); //年
      var month = (now.getMonth() + 1).toString().padStart(2, "0"); //月
      var date = now
        .getDate()
        .toString()
        .padStart(2, "0"); //日
      // var dangy = new Date(year,month,0).getDate()//当月有多少天
      // this.Inbound.date = [`${year}-${month}-01`,`${year}-${month}-${dangy}`]
      // 7天
      var now7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      var year7 = now7.getFullYear(); //年
      var month7 = (now7.getMonth() + 1).toString().padStart(2, "0"); //月
      var date7 = now7
        .getDate()
        .toString()
        .padStart(2, "0"); //日
      this.Inbound.date = [
        `${year7}-${month7}-${date7}`,
        `${year}-${month}-${date}`
      ];
    },
    // 获取管理列表内容
    demand() {
      // console.log(this.Inbound.type);
      this.$api.ERP.sin
        .requestsinlist({
          page_num: this.Inbound.pagenum,
          page_size: 10,
          record_type: Number(this.Inbound.type),
          begin_day: this.Inbound.date[0],
          end_day: this.Inbound.date[1],
          remark: this.Inbound.remark
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.tableData = res.data.datas || [];
            this.Inbound.pagecnt = res.data.page_cnt;
            this.Inbound.rowcnt = res.data.row_cnt;
            this.Inbound.pagenum = res.data.page_num;
            this.multipleSelection = [];
            this.isIndeterminate = false;
            this.checkAll = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 选择全选或取消
    handleCheckAllChange(val) {
      // console.log(this.tableData);
      // console.log(val);
      if (val) {
        // console.log(this.tableData);
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
      console.log(value);
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.tableData.length;
      // console.log(this.checkedCities);
    },
    // 当前是多少页
    handleCurrentChange(val) {
      console.log(`当前页: ${val}`);
      this.Inbound.pagenum = val;
      this.demand();
    },
    // 查询
    inquirequery() {
      this.demand();
    },
    // 重置
    resetstorage() {
      this.Inbound.date = [];
      this.Inbound.type = "";
      this.Inbound.pagenum = 1;
      this.Inbound.pagecnt = 1;
      this.Inbound.rowcnt = 1;
      this.Inbound.remark = "";
      this.tableData = [];
      this.jindst = "1";
      this.daterq();
      this.demand();
    },
    // 点开创建仓库
    xingh() {
      this.form_rule_msg_remark = "";
      this.dialogFormVisible = true;
      this.ProductLibrary.warehouse = "";
      this.ProductLibrary.type = "";
      this.ProductLibrary.tickVal = "";
      this.ProductLibrary.supplier = "";
      this.ProductLibrary.remark = "";
      this.supplies = this.supplinesInit(5);
      this.$api.ERP.sin.requestsinnew_sin_items().then(res => {
        console.log(res);
        this.ProductLibrary.warehousess = res.data.stores;
        this.ProductLibrary.supplierss = res.data.suppliers;
      });
    },
    // 添加物料
    appendmaterial() {
      this.supplies.push(...this.supplinesInit(1));
    },
    //模糊搜索获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse.focus();
        console.log(this.$refs.selectsse);
      });
    },

    // 根据输入的内容模糊查找
    remoteMethod(query) {
      if (query !== "") {
        this.loading = true;
        this.$api.ERP.sin
          .requestsinmat_items({
            name: query,
            page_num: 1,
            page_size: 9999999
          })
          .then(res => {
            this.dimoptions = res.data || [];
            this.loading = false;
          });
      } else {
        this.dimoptions = [];
      }
    },
    // 物料信息清空
    matianforionempty() {
      this.materialnrs = {
        name: "", //名称
        classifyyi: "", //分类一级
        classifyer: "", //分类二级
        units: [], //单位列表
        unit: "", //单位
        amt: "", //价格
        quantity: "", //数量
        totalprices: "", //总价
        propertys: [] //属性列表
      }; // 物料信息内容
    },
    // 批量删除物料
    batchDeleteSupplies(id) {
      const supplies = [...this.supplies];
      const findIndex = supplies.findIndex(item => item.id == id);
      if (findIndex > -1) supplies.splice(findIndex, 1);
      this.supplies = [...supplies];
    },
    // 创建入库
    construction() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_remark) return;
      if (
        this.ProductLibrary.warehouse == "" ||
        this.ProductLibrary.type == "" ||
        this.ProductLibrary.tickVal == ""
      ) {
        this.$message.warning("必选框不能为空");
      } else {
        this.$api.ERP.sin
          .requestsinnew({
            store_id: this.ProductLibrary.warehouse,
            record_type: this.ProductLibrary.type,
            supplier_id:
              this.ProductLibrary.type == 7 ? "" : this.ProductLibrary.supplier,
            fapiao_type: this.ProductLibrary.tickVal * 1, // int     发票类型 普票(传1),专票(传2)
            remark: this.ProductLibrary.remark,
            mat_ids: this.supplies.filter(item => item.name !=='').map(item => item.isEffective && isNaN(item.name * 1) ? item.id * 1 : item.name * 1), //    []int64    物料商品Id列表
            cnts: this.supplies.filter(item => item.name !=='').map(item => item.quantity * 1), //       []int       物料商品对应单位的数量列表
            amts: this.ProductLibrary.tickVal == 2 ? this.supplies.filter(item => item.name !=='').map(item => (item.amt / 1.13).toFixed(2)) : this.supplies.filter(item => item.name !=='').map(item => (item.amt * 1).toFixed(2)), //  []string   物料商品对应采购总金额 使用字符串表示, 最大支持2位小数
            src_amts: this.supplies.filter(item => item.name !=='').map(item => (item.amt * 1).toFixed(2))//  []string   裸价金额,如果普票,实际金额=src_amt,专票的话,实际金额=src_amt/1.13
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.multipleSelection = [];
              this.isIndeterminate = false;
              this.checkAll = false;
              this.dialogFormVisible = false;
              this.demand();
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    },
    // 红冲整单  其他入库单
    noneffective() {
      console.log(this.multipleSelection);
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sin
          .requestsincs({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.demand();
              this.multipleSelection = [];
              this.isIndeterminate = false;
              this.checkAll = false;

              this.multipleSelection = [];
              this.isIndeterminate = false;
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.cfdetails = false;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    // 读取其他入库单详情, 用于信息展示
    showviewdetails(id) {
      this.multipleSelection = [id];
      this.isIndeterminate = true;
      console.log(id);
      this.$api.ERP.sin.requestsinget_f_view({ id: id }).then(res => {
        console.log(res);
        if (res.code == 1) {
          this.viewdetails = res.data;
          this.cfdetails = true;
          this.hcsl= []
          if(this.viewdetails.dtls){
              for (const key in this.viewdetails.dtls) {
                  this.viewdzj += this.viewdetails.fapiao_type == '专票' ? Number(this.viewdetails.dtls[key].a * 1) : Number(this.viewdetails.dtls[key].sa * 1)
              }
          }
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 红冲
    compileprinter() {
      console.log(this.multipleSelection);
      this.cfdetails = false;
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sin
          .requestsinget_f_hc({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.viewdetails = res.data;
              this.hcsl = [];
              for (const key in res.data.dtls) {
                this.hcsl.push({
                  sl: "",
                  id: res.data.dtls[key].id
                });
              }
              this.Reddashed = true;
              // this.$nextTick(()=>{  //次要代码
              //   this.$refs.selectsse[0].focus();
              // })
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "请选择一个进行编辑",
          type: "warning"
        });
      }
    },
    // 红冲确认入库
    hcaffirmReddashed() {
      console.log(this.hcsl);
      var id = [];
      var sl = [];
      for (const key in this.hcsl) {
        if (this.hcsl[key].sl != 0 && this.hcsl[key].sl != "") {
          id.push(this.hcsl[key].id);
          sl.push(Number(this.hcsl[key].sl));
        }
      }
      this.$api.ERP.sin
        .requestsinhc({
          dtl_ids: id,
          cnts: sl
        })
        .then(res => {
          if (res.code == 1) {
            this.Reddashed = false;
            this.demand();
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          } else {
            this.$message.warning(res.msg);
          }
          console.log(res);
        });
    },
    // 类似创建
    effective() {
      console.log(this.multipleSelection);
      this.cfdetails = false;
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sin
          .requestsinget_f_copy({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res.data);
            if (res.code == 1) {
              this.ProductLibrary = {
                warehousess: res.data.stores,
                warehouse: res.data.store_id,
                tickVal: res.data.fapiao_type * 1,
                ticketOption: this.ProductLibrary.ticketOption,
                type: res.data.record_type,
                supplier: res.data.supplier_id || '',
                supplierss: res.data.suppliers,
                remark: res.data.remark
              };
              this.supplies = !res.data.dtls ? this.supplinesInit(5) : [];
              for (const key in res.data.dtls) {
                this.supplies.push({
                  isEffective: true,  // 是否为类似创建
                  id: res.data.dtls[key].id, // id
                  name: res.data.dtls[key].n, // 名字
                  classifyyi: res.data.dtls[key].moc, // 一级分类
                  classifyer: res.data.dtls[key].mtc, // 二级分类
                  unit: res.data.dtls[key].un, // 单位名字
                  quantity: res.data.dtls[key].c, // 数量
                  amt: res.data.dtls[key].p //计算好的入库金额
                });
              }
              this.dialogFormVisible = true;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },

    // 初始化新增入库表格信息
    supplinesInit(num) {
      return new Array(num).fill(1).map((item, index) => ({
        id: this.supplies.length + 1 + index, // id
        name: "", // 名字
        classifyyi: "", // 一级分类
        classifyer: "", // 二级分类
        unit: "", // 单位名字
        quantity: 1, // 数量
        amt: 0 // 入库小计
      }));
    },

    // 选择物料名称
    changeNameHandle(itemInfo) {
      const supplies = [...this.supplies];
      const info = this.dimoptions.find(item => item.id == itemInfo.name);
      supplies.forEach(el => {
        if (el.id == itemInfo.id) {
          el.classifyyi = info.moc;
          el.classifyer = info.mtc;
          el.unit = info.un;
        }
      });
      this.supplies = [...supplies];
      this.dimoptions = []
    }
  },
  computed: {
    materialnr() {
      return JSON.parse(JSON.stringify(this.materialnrs));
    },
    hcsls() {
      return JSON.parse(JSON.stringify(this.hcsl || []));
    },
    supp() {
      return JSON.parse(JSON.stringify(this.supplies));
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
      this.RollMaxHeight(that.windowHeigh);
      //   console.log("实时屏幕宽度：",val, that.windowWidt );
    },
    // 设置日期
    jindst: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);
        var now = new Date();
        var year = now.getFullYear(); //年
        var month = (now.getMonth() + 1).toString().padStart(2, "0"); //月
        var date = now
          .getDate()
          .toString()
          .padStart(2, "0"); //日
        // console.log(now.getTime());
        if (after == 1) {
          // 7天
          this.daterq();
          this.demand();
        } else if (after == 2) {
          //一个月
          // console.log(now.setMonth(now.getMonth()-1));
          now.setMonth(now.getMonth() - 1);
          var now1 = new Date(now.setMonth(now.getMonth() - 1 + 1));
          var year1 = now1.getFullYear(); //年
          var month1 = (now1.getMonth() + 1).toString().padStart(2, "0"); //月
          var date1 = now1
            .getDate()
            .toString()
            .padStart(2, "0"); //日
          this.Inbound.date = [
            `${year1}-${month1}-${date1}`,
            `${year}-${month}-${date}`
          ];
          this.demand();
        } else if (after == 3) {
          //3个月
          // console.log(now.setMonth(now.getMonth()-3));
          now.setMonth(now.getMonth() - 3);
          var now3 = new Date(now.setMonth(now.getMonth() - 1 + 1));
          var year3 = now3.getFullYear(); //年
          var month3 = (now3.getMonth() + 1).toString().padStart(2, "0"); //月
          var date3 = now3
            .getDate()
            .toString()
            .padStart(2, "0"); //日
          this.Inbound.date = [
            `${year3}-${month3}-${date3}`,
            `${year}-${month}-${date}`
          ];
          this.demand();
        }
      }
    },
    // 模糊查询物料
    dimvalue: function(after, before) {
      // console.log(after);
      // console.log(before);
      if (after) {
        if (after != before) {
          // console.log(after);
          // 拿到名字
          var nam = {
            name: "",
            id: ""
          };
          for (const key in this.dimoptions) {
            if (this.dimoptions[key].id == after) {
              nam.name = this.dimoptions[key].n;
              nam.id = this.dimoptions[key].id;
            }
          }

          this.matianforionempty();
          this.$api.ERP.sin.requestsinmat_attrs({ id: after }).then(res => {
            console.log(res.data);
            this.materialnrs.id = nam.id;
            this.materialnrs.name = nam.name;
            this.materialnrs.classifyyi = res.data.one_cate_name;
            this.materialnrs.classifyer = res.data.two_cate_name;
            this.materialnrs.units = res.data.units || [];
            this.materialnrs.propertys = res.data.attrs || [];
            for (const iterator of res.data.attrs || []) {
              this.materi.push("");
            }
            console.log(this.materi);
          });
        }
      }
    },
    // 信息操作
    // materialnr: {
    //   deep: true,
    //   handler: function(after, before) {
    //     // 选择单位出现价格
    //     if (after.price == before.price) {
    //       if (after.unit == "") {
    //         this.materialnrs.price = "";
    //       } else {
    //         if (after.quantity == before.quantity) {
    //           for (const key in after.units) {
    //             if (after.units[key].id == after.unit) {
    //               this.materialnrs.price = after.units[key].buy_price;
    //             }
    //           }
    //         }
    //       }
    //     }

    //     // 只让输入数字  限制小数点后有两位就不能输入了
    //     if (after.price) {
    //       var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
    //       // console.log(reg.test(after.price));
    //       if (!reg.test(after.price)) {
    //         this.materialnrs.price = before.price;
    //       }
    //     }
    //     // 只让输入数字
    //     if (after.quantity) {
    //       var reg = /^[0-9]*$/;
    //       // console.log(after.quantity);
    //       // console.log(!reg.test(after.quantity));
    //       if (!reg.test(after.quantity)) {
    //         this.materialnrs.quantity = before.quantity;
    //       }
    //     }
    //     // console.log(after.price != '');
    //     console.log(after.quantity);
    //     // console.log(after.price != '' && after.quantity != "");
    //     if (after.price != "" && after.quantity != "") {
    //       this.totalprices = (
    //         Number(after.price) * Number(after.quantity || 0)
    //       ).toFixed(2);
    //     } else {
    //       this.totalprices = "0.00";
    //     }
    //   }
    // },
    // 红冲数量为数字 不能大于出库数量
    // hcsls: {
    //   deep: true,
    //   handler: function(after, before) {
    //     console.log(after);
    //     if (after) {
    //       var s = 0;
    //       for (const key in after) {
    //         // console.log(after[key].sl);
    //         if (after[key].sl) {
    //           if (after[key].sl != before[key].sl) {
    //             // console.log(this.viewdetails.dtls[key].a);
    //             var reg = /^[0-9]*$/g;
    //             if (reg.test(after[key].sl)) {
    //               if (after[key].sl > this.viewdetails.dtls[key].rc) {
    //                 this.hcsl[key].sl = this.viewdetails.dtls[key].rc + "";
    //               }
    //             } else {
    //               console.log("--");
    //               this.hcsl[key].sl = (before[key].sl || "") + "";
    //             }
    //           }
    //         }
    //         s +=
    //           this.viewdetails.dtls[key].sp * this.viewdetails.dtls[key].sc -
    //           (this.viewdetails.dtls[key].rta / this.viewdetails.dtls[key].rc) *
    //             after[key].sl;
    //       }
    //       this.viewdetails.total_amt = s;
    //     }
    //   }
    // },
    // 只能输数字
    // supp: {
    //   deep: true,
    //   handler: function(after, before) {
    //     // console.log(after);
    //     for (const key in after) {
    //       var reg = /^[0-9]+(\.[0-9]{0,2})?$/;
    //       if (!reg.test(after[key].price)) {
    //         this.supplies[key].price = before[key].price;
    //       }
    //       var re = /^[0-9]*$/g;
    //       if (!re.test(after[key].quantity)) {
    //         this.supplies[key].quantity = before[key].quantity;
    //       }
    //     }
    //     // quantity
    //     // price
    //   }
    // }
  }
};
</script>
<style>
/* 靠右 */
.sin .el-dialog {
  margin: 0px 0px 0px auto !important;
  background-color: #f9f9f9;
  height: 100%;
  position: relative;
}

.sin .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.sin .el-dialog__body {
  padding: 0px 20px 30px 20px;
  overflow-y: scroll !important;
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.sin .el-dialog {
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.sin {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

.sin .gaib {
  width: 500px !important;
  display: flex;
  align-items: center;
}

.conceal {
  display: block;
}

.monad,
.show {
  display: none;
}

/* 必填 */
.sin .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
  /* padding-top: 10px; */
  line-height: 40px;
}

.sin .controlling {
  width: 230px !important;
  line-height: 40px;
}

.sin .reqfieldsd {
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
.sin .tiaodd {
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

.sin .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0;
}

.sin .nodata img {
  width: 60px;
  height: 60px;
}

.sin .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

.sin .drag-list .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.sin .drag-list .nodata img {
  width: 60px;
  height: 60px;
}

.sin .drag-list .nodata .hint {
  font-size: 13px !important;
}

/* 全选字体大小 */
.sin .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

/* 给一级分类二级分类加外边距和圆角 */
.sin .el-radio-button {
  margin-right: 6px;
  margin-bottom: 6px;
  /* overflow: hidden; */
  /* border: 1px solid #f5f5f5; */
}

.sin .el-radio-button__inner {
  border-radius: 4px !important;
}

/* 去除瑕疵 */
.sin .el-radio-button__orig-radio:checked + .el-radio-button__inner {
  box-shadow: none;
}

/* 选中状态颜色背景边框 */
.sin .el-radio-button__orig-radio:checked + .el-radio-button__inner {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #6a9eff !important;
  color: #6a9eff;
}

/* 表格内文字居中 */
.sin .alignment {
  text-align: right !important;
  padding-right: 15px;
}

.sin .Writmiddle .el-input__inner {
  text-align: right;
}

.sin .Writmiddle .el-input__inner::-webkit-input-placeholder {
  text-align: center;
}

/* 内容 */
.sin .sin-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.sin .sin-controller {
  height: 54px;
  background-color: #e5e5e5;
  display: flex;
  align-items: center;
}

.sin .sin-rkrq {
  width: 100%;
  color: #40404e;
  overflow: hidden;
  font-size: 13px;
  line-height: 14px;
}

.sin .sin-rkrq .rkrq {
  display: inline-flex;
  align-items: center;
  margin: 0 0 14px 0;
}

.sin .sin-rkrq .rkrq:nth-child(1) {
  width: 670px !important;
}

.sin .sin-rkrq .rkrq:nth-child(2) {
  width: 275px !important;
}

.sin .sin-rkrq .rkrq:nth-child(3) {
  width: 250px !important;
}

.sin .sin-rkrq .rkrq:nth-child(4) {
  width: 150px !important;
}

/* 选择近几天 */
.sin .sin-rkrq .rkrq .danxk {
  height: 34px;
  margin-right: 10px;
  display: inline-flex;
  align-items: center;
}

.sin .sin-rkrq .rkrq .danxk img {
  display: inline-block;
  width: 12px;
  height: 12px;
  margin-right: 6px;
}

.sin .sin-rkrq .rkrq .danxk .el-radio-button {
  margin: 0px 4px;
  box-shadow: none !important;
}

.sin .sin-rkrq .rkrq .danxk .el-radio-button__inner {
  border-radius: 19px !important;
  border: 0px !important;
  background-color: transparent;
  color: #40404e;
  font-size: 12px;
  display: flex;
  align-items: center;
  line-height: 16px;
  padding: 5px 15px;
}

.sin
  .sin-rkrq
  .rkrq
  .danxk
  .el-radio-button__orig-radio:checked
  + .el-radio-button__inner {
  background-color: transparent !important;
  color: #2170ff;
}

.sin .ewdetai {
  color: #2170ff;
  cursor: pointer;
}

.sin .layouts {
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.sin .AddPrincipal {
  color: #4eadfc;
}

.sin .compatibility {
  display: flex;
  align-items: center;
  /* margin-bottom: 10px; */
}

.sin .compatibils {
  margin-bottom: 10px;
}

.sin .required {
  width: 60px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.sin .bisdf {
  height: 100%;
  text-align: top;
}

/* 取消按钮 */
.sin .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.sin .el-dialog {
  background-color: #f9f9f9;
}

.sin .el-input__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
  height: 30px;
  line-height: 30px;
}

.sin .el-dialog__title,
.sin .el-dialog__headerbtn .el-dialog__close,
.sin .el-form-item__label {
  color: #1a1a21;
}

.sin .el-input {
  width: 190px;
}

.sin .el-form-item {
  display: flex;
  margin: 0;
}

.sin .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

.sin .el-checkbox__input.is-disabled.is-checked .el-checkbox__inner {
  background-color: rgba(0, 0, 0, 0) !important;
}

.sin .el-dialog {
  width: 30vw;
}

.sin .has-gutter {
  border: 1px solid #f5f5f5;
}

.sin table thead tr th,
.sin table tbody tr td {
  height: 40px;
  font-size: 14px;
}

/* 下拉框 */
.el-select-dropdown__wrap {
  background-color: #f5f5f5;
}

.el-select-dropdown__empty {
  background-color: #f5f5f5;
  color: #40404e;
}

.el-select-dropdown__item.selected {
  background-color: #e5e5e5;
}

.el-select__popper.el-popper[role="tooltip"] {
  border: 1px solid #f5f5f5;
}

.el-select__popper.el-popper[role="tooltip"][data-popper-placement^="bottom"]
  .el-popper__arrow::before {
  border: 1px solid #f5f5f5;
  background-color: #f5f5f5;
}

.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: #e5e5e5;
}

.el-select-dropdown__item.selected {
  color: #40404e;
}

.el-select-dropdown__item {
  color: #40404E;
}

.el-select-dropdown {
  border: 1px solid #f5f5f5;
}

/* 新增仓库 */
.sin .dialogFormVisible .el-dialog {
  width: 1280px;
  /* width: 80vw !important; */
  /* min-width: 520px !important;
        max-width:540px !important; */
}

.sin .dialogFormVisible .rkrq {
  height: 54px;
  width: 1240px;
  background-color: #e5e5e5;
  display: flex;
  align-items: center;
  border-top: 1px solid #2c2d36;
}

.sin .el-tag {
  background-color: rgba(0, 0, 0, 0);
  margin-right: 10px;
  margin-bottom: 10px;
  color: #40404e;
}

.sin .el-tag i {
  color: #40404e;
}

.sin .tidsesfe {
  display: flex;
}

/* 多行文本输入框 */
.sin .el-textarea__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
  width: 100%;
  border-color: #C0C4CC
}

.sin .el-input__count {
  background-color: #1a1a20;
  color: #40404e;
  right: -45px;
  height: 20px;
  bottom: 5px;
  line-height: 20px;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 新增物料 */
.sin .addmaterial {
  /* margin-top: 30px; */
  padding-top: 20px;
  /* border-top:2px solid #443f3f; */
}

.sin .dialogFormVisible .zhuixiaoi {
  width: 1240px;
  /* margin-top: 20px; */
}

.sin .dialogFormVisible .zhuixiaoi .el-checkbox-group {
  height: 40px;
  line-height: 36px !important;
}

.sin .dialogFormVisible .zhuixiaoi .limiting {
  max-height: 360px !important;
  overflow-y: auto !important;
  /* overflow: overlay; */
}

.sin .dialogFormVisible .drag-list td:nth-of-type(2),
.sin .dialogFormVisible .mmodity th:nth-of-type(2) {
  width: 100px;
}

.sin .dialogFormVisible .drag-list td:nth-of-type(3),
.sin .dialogFormVisible .mmodity th:nth-of-type(3) {
  width: 200px;
}

.sin .dialogFormVisible .drag-list td:nth-of-type(4),
.sin .dialogFormVisible .mmodity th:nth-of-type(4) {
  width: 130px;
}

.sin .dialogFormVisible .drag-list td:nth-of-type(5),
.sin .dialogFormVisible .mmodity th:nth-of-type(5) {
  width: 130px;
}

.sin .dialogFormVisible .drag-list td:nth-of-type(6),
.sin .dialogFormVisible .mmodity th:nth-of-type(6) {
  width: 80px;
}

.sin .dialogFormVisible .drag-list td:nth-of-type(7),
.sin .dialogFormVisible .mmodity th:nth-of-type(7) {
  width: 110px;
}
.sin .dialogFormVisible .drag-list td:nth-of-type(8),
.sin .dialogFormVisible .mmodity th:nth-of-type(8) {
  width: 110px;
}
.sin .dialogFormVisible .drag-list td:nth-of-type(9),
.sin .dialogFormVisible .mmodity th:nth-of-type(9) {
  width: 110px;
}
.sin .dialogFormVisible .drag-list td:nth-of-type(10),
.sin .dialogFormVisible .mmodity th:nth-of-type(10) {
  width: 130px;
}

/* 查看 */

.sin .viewdetailscls .el-dialog {
  width: 1280px;
  /* width: 80vw !important; */
  /* min-width: 520px !important;
        max-width:540px !important; */
}

/* 必填 */
.sin .viewdetailscls .mandatory {
  color: 40404e;
}

.sin .viewdetailscls .el-form {
  padding: 0px;
  margin: 20px;
  background-color: #eee;
  border: 1px solid #f5f5f5;
  border-radius: 8px;
}

.sin .viewdetailscls .lbds {
  color: #40404e;
  margin-left: 20px;
  font-size: 18px;
}

.sin .viewdetailscls .addmaterial {
  /* display: flex;
        justify-content: center; */
  margin-left: 20px;
  max-width: 1180px;
  overflow-x: scroll;
}

.sin .viewdetailscls .addmatssial {
  max-width: 1180px;
  overflow-x: scroll;
}

.sin .viewdetailscls .materialnr {
  width: 200px;
}

.sin .viewdetailscls .materialnrs {
  width: 600px;
}

/* .sin .viewdetailscls .zhuixiaoi .limiting{
        max-height: 400px;
        overflow-y: scroll;
    } */
/* 明细单列表 */
.sin .viewdetailscls .materialnr,
.sin .viewdetailscls label,
.sin .viewdetailscls .materialnrs {
  color: #40404e;
  font-size: 14px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(2),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(2) {
  width: 180px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(3),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(3) {
  width: 130px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(4),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(4) {
  width: 130px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(5),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(5) {
  width: 120px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(6),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(6) {
  width: 90px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(7),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(7) {
  width: 90px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(8),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(8) {
  width: 120px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(9),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(9) {
  width: 90px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(10),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(10) {
  width: 90px;
}

.sin .viewdetailscls .addmaterial .drag-list td:nth-of-type(11),
.sin .viewdetailscls .addmaterial .mmodity th:nth-of-type(11) {
  width: 110px;
}

/* 红冲操作单列表 */
.sin .viewdetailscls .addmatssial {
  margin-left: 20px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(2),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(2) {
  width: 180px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(3),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(3) {
  width: 150px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(4),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(4) {
  width: 90px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(5),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(5) {
  width: 90px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(6),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(6) {
  width: 120px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(7),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(7) {
  width: 90px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(8),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(8) {
  width: 90px;
}

.sin .viewdetailscls .addmatssial .drag-list td:nth-of-type(9),
.sin .viewdetailscls .addmatssial .mmodity th:nth-of-type(9) {
  width: 150px;
}

/* 红冲 */
.sin .hcwdetailscls .el-dialog {
  width: 1280px;
}

/* 必填 */
.sin .hcwdetailscls .mandatory {
  color: 40404e;
}

.sin .hcwdetailscls .el-form {
  padding: 0px;
  margin: 20px;
  background-color: #eee;
  border: 1px solid #f5f5f5;
  border-radius: 8px;
}

.sin .hcwdetailscls .addmaterial {
  margin-left: 20px;
  max-height: 1180px;
  overflow-x: scroll;
}

/* .sin .hcwdetailscls .zhuixiaoi .limiting{
        max-height: 400px;
        overflow-y: scroll;
    } */
.sin .hcwdetailscls .materialnr {
  width: 200px;
}

.sin .hcwdetailscls .materialnrs {
  width: 600px;
}

.sin .hcwdetailscls .el-input-number {
  width: 100%;
}

.sin .hcwdetailscls .materialnr,
.sin .hcwdetailscls label,
.sin .hcwdetailscls .materialnrs {
  color: #40404e;
  font-size: 14px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(2),
.sin .hcwdetailscls .mmodity th:nth-of-type(2) {
  width: 270px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(3),
.sin .hcwdetailscls .mmodity th:nth-of-type(3) {
  width: 130px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(4),
.sin .hcwdetailscls .mmodity th:nth-of-type(4) {
  width: 130px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(5),
.sin .hcwdetailscls .mmodity th:nth-of-type(5) {
  width: 100px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(6),
.sin .hcwdetailscls .mmodity th:nth-of-type(6) {
  width: 90px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(7),
.sin .hcwdetailscls .mmodity th:nth-of-type(7) {
  width: 110px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(8),
.sin .hcwdetailscls .mmodity th:nth-of-type(8) {
  width: 120px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(9),
.sin .hcwdetailscls .mmodity th:nth-of-type(9) {
  width: 120px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(10),
.sin .hcwdetailscls .mmodity th:nth-of-type(10) {
  width: 120px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(11),
.sin .hcwdetailscls .mmodity th:nth-of-type(11) {
  width: 120px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(12),
.sin .hcwdetailscls .mmodity th:nth-of-type(12) {
  width: 100px;
}

.sin .hcwdetailscls .drag-list td:nth-of-type(13),
.sin .hcwdetailscls .mmodity th:nth-of-type(13) {
  width: 120px;
}

/* 添加物料 */
/* 模糊查询 */
.sin .search .el-dialog {
  width: 50vw !important;
  min-width: 550px !important;
  max-width: 560px !important;
}

.sin .search .mandatory {
  width: 100px;
}

.sin .search .topwidth {
  width: 300px;
  margin-top: 30px;
  margin-left: 30px;
}

/* 物料信息 */
.sin .search .materialsinformation .el-form {
  /* margin-top: 20px; */
  padding-top: 10px !important;
  /* border-top:2px solid rgb(88, 88, 88) ; */
}

.sin .search .materialsinformation .information {
  color: #40404e;
  font-size: 16px;
}

.sin .search .materialsinformation .materialnr {
  color: #40404e;
}

.sin .search .materialsinformation .protyfsfg {
  /* margin: 0 0 10px; */
  color: #40404e;
  width: 320px;
  display: flex;
  justify-content: space-between;
}

.sin .search .materialsinformation .protyfsfg input {
  width: 230px;
}

/* 仓库列表 */
.zsykd {
  width: 100%;
  overflow-x: scroll !important;
}

.sin .zhuixiaoi {
  width: 1600px;
  /* min-width: 1300px; */
  /* overflow: hidden; */
  border-collapse: collapse;
  color: #40404e;
}

.sin .zhuixiaoi .mmodity tr th {
  height: 36px;
  line-height: 36px;
  text-align: left;
  /* border-bottom: solid 1px #f5f5f5;  */
  font-weight: 600;
  padding-left: 20px;
}
.sin .zhuixiaoi .mmodity tr th .el-checkbox__label {
  font-size: 14px;
  font-weight: 600;
  color: #40404e;
}

.sin .zhuixiaoi .limiting .drag-list td {
  height: 36px;
  line-height: 36px;
  text-align: left;
  font-weight: 400;
  padding-left: 20px;
}

.sin .zhuixiaoi .limiting .drag-list {
  border-top: solid 1px #f5f5f5;
  display: block;
  /* width: calc(100% - 17px); */
  display: flex;
}

.sin .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.sin .zhuixiaoi .mmodity tr {
  display: flex;
  background-color: #f5f5f5;
}

.sin .zhuixiaoi .limiting {
  border-bottom: solid 1px #f5f5f5;
  overflow-y: auto !important;
  max-height: 540px;
  display: block;
}

.sin .drag-list td:nth-of-type(1),
.sin .mmodity th:nth-of-type(1) {
  width: 50px;
}

.sin .mmodity th:nth-of-type(2),
.sin .drag-list td:nth-of-type(2) {
  width: 110px;
  /* display:inline-block;
        width:calc(100% - 840px); */
  /* width: 100%; */
}

.sin .drag-list td:nth-of-type(3),
.sin .mmodity th:nth-of-type(3) {
  width: 140px !important;
}

.sin .drag-list td:nth-of-type(4),
.sin .mmodity th:nth-of-type(4) {
  width: 140px;
}

.sin .drag-list td:nth-of-type(5),
.sin .mmodity th:nth-of-type(5) {
  width: 140px;
}

.sin .drag-list td:nth-of-type(6),
.sin .mmodity th:nth-of-type(6) {
  width: 140px;
}

.sin .drag-list td:nth-of-type(7),
.sin .mmodity th:nth-of-type(7) {
  width: 140px;
}

.sin .drag-list td:nth-of-type(8),
.sin .mmodity th:nth-of-type(8) {
  width: 140px;
}

.sin .drag-list td:nth-of-type(9),
.sin .mmodity th:nth-of-type(9) {
  width: 140px;
}

.sin .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.sin .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

.sin .zhuixiaoi .el-checkbox__label {
  color: #40404e;
}

/*  */
.sin .zhuixiaoi .chaoguogai {
  height: 20px;
  /* text-align: center; */
  line-height: 20px;
  width: 136px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 日期选择器 */
.sin .sin-rkrq .rkrq .el-range-editor .el-range-input {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
}

.sin .sin-rkrq .rkrq .el-date-editor .el-range-separator,
.sin .sin-rkrq .rkrq .el-date-editor .el-range__icon {
  color: #40404e;
  line-height: 22px;
}

.el-picker-panel {
  background-color: #1a1a20;
}

/* 年月日 */
.el-date-range-picker__header {
  color: #40404e;
}

/* 加减年月  */
.el-icon-d-arrow-left,
.el-icon-arrow-left,
.el-icon-d-arrow-right,
.el-icon-arrow-right {
  color: #40404e;
}

.el-date-table tbody tr th {
  color: #404041;
  font-weight: 600;
}

.el-date-table td.next-month,
.el-date-table td.prev-month {
  color: #77797c;
}

.el-picker-panel {
  color: #40404e;
}

.in-range {
  color: #000;
}

.el-date-table td.in-range div {
  background-color: #f2f6fc;
}

/* 分页 */
.sin .Pagination {
  /* width: 1093px; */
  text-align: right;
  margin-top: 20px;
}

.sin .Pagination .el-pagination.is-background .btn-next,
.sin .Pagination .el-pagination.is-background .btn-prev,
.sin .Pagination .el-pagination.is-background .el-pager li {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
  color: #40404e;
}

.sin .Pagination .btn-prev {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
}

.sin .Pagination .el-pagination {
  padding: 0;
}

.sin .Pagination .el-pagination .btn-next .el-icon,
.sin .Pagination .el-pagination .btn-prev .el-icon {
  color: #40404e;
}

.sin
  .Pagination
  .el-pagination.is-background
  .el-pager
  li:not(.disabled).active {
  color: #409eff;
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #409eff;
}
</style>

<style media="print">
@page {
  size: auto A4 landscape;
  margin: 5mm;
}

@media print {
  html {
    /* margin-left: 30px; */
  }

  .printsin .conceal {
    display: none;
  }

  .printsin .show {
    display: block;
  }

  .printsin .monad {
    font-weight: bold;
    display: block;
    font-size: 30px;
    margin-top: 50px;
    color: #000;
    text-align: center;
  }

  .printsin .tidsesfe {
    display: flex;
  }

  .printsin .compatibility {
    display: flex;
    align-items: center;
  }

  .printsin .mandatory {
    color: #000;
    width: 140px;
    text-align: right;
    /* padding-top: 10px; */
  }

  .printsin .controlling {
    width: 370px !important;
    line-height: 40px;
  }

  .printsin .reqfieldsd {
    font-size: 14px;
    padding-right: 4px;
    color: #ce4153;
    /* 文字不可选中 */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .printsin .zhuixiaoi {
    overflow: hidden;
    border-collapse: collapse;
    color: #000;
  }

  .printsin .zhuixiaoi .mmodity tr th {
    height: 40px;
    line-height: 40px;
    text-align: left;
    /* border: solid 1px #f5f5f5; */
    border-top: solid 1px #f5f5f5;
    /* border-right: solid 1px #f5f5f5;  */
    border-bottom: solid 1px #f5f5f5;
    background-color: #2d2e38;
    font-weight: 400;
    padding-left: 20px;
  }

  .printsin .zhuixiaoi .limiting .drag-list td {
    height: 40px;
    line-height: 40px;
    text-align: left;
    white-space: normal;
    word-break: break-all;
    padding-left: 20px;
    /* border: solid 1px #f5f5f5; */
    border-bottom: solid 1px #f5f5f5;
    /* border-right:solid 1px #f5f5f5; */
  }

  .printsin .zhuixiaoi .limiting .drag-list {
    display: block;
    display: flex;
  }

  .printsin .zhuixiaoi .mmodity {
    width: 100%;
    display: block;
  }

  .printsin .zhuixiaoi .mmodity tr {
    display: flex;
  }

  .printsin .el-form-item {
    display: flex;
    margin: 0;
  }

  .printsin .drag-list td,
  .printsin .mmodity th {
    font-size: 13px;
  }

  .printsin .el-dialog {
    width: 1100px;
  }

  .printsin .el-form {
    padding-top: 10px;
  }

  .printsin .addmaterial {
    display: flex;
    justify-content: center;
  }

  .printsin .materialnr {
    width: 200px;
  }

  .printsin .materialnrs {
    width: 600px;
  }

  .printsin .materialnr,
  .printsin label,
  .printsin .materialnrs {
    color: #000;
  }

  .printsin .drag-list td:nth-of-type(1),
  .printsin .mmodity th:nth-of-type(1) {
    width: 50px;
  }

  .printsin .drag-list td:nth-of-type(2),
  .printsin .mmodity th:nth-of-type(2) {
    width: 200px;
  }

  .printsin .drag-list td:nth-of-type(3),
  .printsin .mmodity th:nth-of-type(3) {
    width: 120px;
  }

  .printsin .drag-list td:nth-of-type(4),
  .printsin .mmodity th:nth-of-type(4) {
    width: 60px;
  }

  .printsin .drag-list td:nth-of-type(5),
  .printsin .mmodity th:nth-of-type(5) {
    width: 70px;
  }

  .printsin .drag-list td:nth-of-type(6),
  .printsin .mmodity th:nth-of-type(6) {
    width: 70px;
  }

  .printsin .drag-list td:nth-of-type(7),
  .printsin .mmodity th:nth-of-type(7) {
    width: 70px;
  }

  .printsin .drag-list td:nth-of-type(8),
  .printsin .mmodity th:nth-of-type(8) {
    width: 60px;
  }

  .printsin .drag-list td:nth-of-type(9),
  .printsin .mmodity th:nth-of-type(9) {
    width: 100px;
  }

  .printsin .drag-list td:nth-of-type(10),
  .printsin .mmodity th:nth-of-type(10) {
    width: 70px;
  }

  .printsin .drag-list td:nth-of-type(11),
  .printsin .mmodity th:nth-of-type(11) {
    width: 90px;
  }

  .printsin .drag-list td:nth-of-type(12),
  .printsin .mmodity th:nth-of-type(12) {
    width: 100px;
  }

  .printsin .signature {
    display: flex;
    margin-top: 50px;
  }

  .printsin .signature > div {
    margin-left: 30px;
    display: flex;
  }

  .printsin .signature span {
    font-size: 20px;
  }

  .printsin .signature .xian {
    width: 180px;
    height: 30px;
    border-bottom: 1px solid #000;
  }
}

.el-input__icon {
  line-height: 30px;
}

.out_sum .el-input {
  opacity: 1;
  width: 190px;
}

.el-button {
  font-size: 13px;
  line-height: 14px;
  padding: 8px 20px;
  height: 30px;
}

.el-range-editor.el-input__inner {
  width: 287px;
  height: 30px;
  line-height: 30px;
}

.el-date-editor .el-range__close-icon {
  line-height: 22px;
}

.dialogFormVisible .el-input,
.addmaterial .el-input {
  width: 100%;
}

.drag-list-check {
  /* background: rgba(39, 52, 82, 0.5) !important; */
}
</style>