<template>
  <div class="sind">
    <div class="stairfl">
      <div class="classification">状态：</div>
      <div class="stairastrict">
        <el-radio-group v-model="Inbound.state" class="container">
          <el-radio-button label="0">全部</el-radio-button>
          <el-radio-button label="2">整单红冲</el-radio-button>
          <el-radio-button label="6">待入库</el-radio-button>
          <el-radio-button label="9">异议中</el-radio-button>
          <el-radio-button label="7">异议已处理</el-radio-button>
          <el-radio-button label="5">已完成</el-radio-button>
        </el-radio-group>
      </div>
    </div>
    <div class="sind-rkrq">
      <div class="rkrq">
        <span>出库日期：</span>
        <el-radio-group v-model="jindst" class="danxk">
          <el-radio-button label="1">
            <img v-show="jindst != 1" src="@/assets/img/date_label_grey.png" alt />
            <img v-show="jindst == 1" src="@/assets/img/date_label_selete.png" alt />
            近七天
          </el-radio-button>
          <el-radio-button label="2">
            <img v-show="jindst != 2" src="@/assets/img/date_label_grey.png" alt />
            <img v-show="jindst == 2" src="@/assets/img/date_label_selete.png" alt />
            近1个月
          </el-radio-button>
          <el-radio-button label="3">
            <img v-show="jindst != 3" src="@/assets/img/date_label_grey.png" alt />
            <img v-show="jindst == 3" src="@/assets/img/date_label_selete.png" alt />
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
        <span>出库仓库：</span>
        <el-select v-model="Inbound.cklx" placeholder="全部" @change="cdemand" clearable>
          <el-option label="全部" value="0"></el-option>
          <el-option v-for="(item,i) in cklxnr" :key="i" :label="item.n" :value="item.id"></el-option>
        </el-select>
      </div>
      <div class="rkrq">
        <!-- <el-button type="primary" @click="cdemand">查询</el-button> -->
        <el-button type="primary" @click="resetstorage">重置</el-button>
      </div>
    </div>

    <div class="sind-controller">
      <!-- <el-button type="primary" style="margin-left: 16px;" @click="xingh">申请售后</el-button> -->
      <characters-button @click.native="xingh" colors="#f5f5f5" wz="申请售后"></characters-button>
      <characters-button @click.native="compileprinter" colors="#f5f5f5" wz="确认入库"></characters-button>
      <characters-button @click.native="noneffective" colors="#f5f5f5" wz="部分入库"></characters-button>
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
              <th>入库仓库</th>
              <th>出库仓库</th>
              <th>
                <div class="alignment">入库成本</div>
              </th>
              <th>入库时间</th>
              <th>入库操作人</th>
              <th>出库时间</th>
              <th>出库操作人</th>
              <th>状态</th>
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
              <td>
                <ellipsis-tooltip :text="item.isn || '-----'"></ellipsis-tooltip>
              </td>
              <td>
                <ellipsis-tooltip :text="item.osn || '-----'"></ellipsis-tooltip>
              </td>
              <td>
                <div class="alignment">{{item.ta}}</div>
              </td>
              <td>{{item.ist}}</td>
              <td>{{item.ien}}</td>
              <td>{{item.ost}}</td>
              <td>{{item.oen}}</td>
              <td>{{item.s}}</td>
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
        style="display: inline-block;position: absolute;top: 0;left: 0;z-index: 100;background-color: #f9f9f9;"
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
              <th>入库仓库</th>
              <th>出库仓库</th>
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
              <td>
                <ellipsis-tooltip :text="item.isn || '-----'"></ellipsis-tooltip>
              </td>
              <td>
                <ellipsis-tooltip :text="item.osn || '-----'"></ellipsis-tooltip>
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
        :total="Inbound.rowcnt"
      ></el-pagination>
    </div>

    <!-- 部分入库 -->
    <div v-show="dialogFormVisible" class="dialogFormVisible">
      <el-dialog
        title="部分入库"
        :visible.sync="dialogFormVisible"
        @close="dialogFormVisible = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>调拨单单号：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.code || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库仓库：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.out_store_name || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>入库仓库：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.in_store_name || '---'}}</div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库操作员名称：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.out_emp_name || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库时间：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.out_store_time || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库总成本：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.total_amt || '---'}}</div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>备注：
              </div>
              <div class="materialnr gaib">{{ProductLibrary.remark || '---'}}</div>
            </div>
          </div>
        </el-form>
        <div class="layouts">说明：请核实入库数量是否正确，数量有误的处理成异议单，确认数量默认为零，异议备注是必填写的，除待确认数量和确认数量一致以外。</div>
        <div class="addmaterial">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>物料名称</th>
                <th>一级分类</th>
                <th>二级分类</th>
                <th>单位</th>
                <th>
                  <div class="alignment">成本单价</div>
                </th>
                <th>
                  <div class="alignment">待确认数量</div>
                </th>
                <th>确认数量</th>
                <th>
                  <div class="alignment">成本小计</div>
                </th>
                <th>异议原因</th>
              </tr>
            </thead>
            <tbody class="limiting">
              <tr v-for="(item,i) in supplies" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.moc || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.mtc || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.un || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <div class="alignment">{{item.a}}</div>
                </td>
                <td>
                  <div class="alignment">{{item.c}}</div>
                </td>
                <td>
                  <el-input
                    v-model="item.sl"
                    placeholder="请输入数量"
                    @input="clearRemarkHandle(item)"
                    class="Writmiddle"
                    ref="selectsse"
                  />
                </td>
                <td>
                  <div class="alignment">{{item.a*(item.sl||0) | decimal}}</div>
                </td>
                <td>
                  <el-input
                    :disabled="item.disabled"
                    v-model="item.remark"
                    :placeholder="item.c == item.sl?'---':'请输入异议备注'"
                    ref="seltsse"
                  />
                </td>
              </tr>
            </tbody>
          </table>
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
        <!-- <div> -->
        <div id="print">
          <div class="printsind">
            <div class="monad">调拨入库单</div>
              <div class="form m-t-6" style="background: #eee;border-radius:10px">
                <div class="row" layout="row" layout-align="start center">
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">调拨单单号：</div>
                    <div class="value" style="width:150px">{{viewdetails.code}}</div>
                  </div>
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">入库仓库：</div>
                    <div class="value" style="width:150px">{{viewdetails.in_store_name}}</div>
                  </div>
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">出库仓库：</div>
                    <div class="value" style="width:150px">{{viewdetails.out_store_name}}</div>
                  </div>
                </div>
                <div class="row" layout="row" layout-align="start center">
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">入库时间：</div>
                    <div class="value" style="width:150px">{{viewdetails.in_store_time}}</div>
                  </div>
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">出库时间：</div>
                    <div class="value" style="width:150px">{{viewdetails.out_store_time}}</div>
                  </div>
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">入库操作员：</div>
                    <div class="value" style="width:150px">{{viewdetails.in_emp_name}}</div>
                  </div>
                </div>
                <div class="row" layout="row" layout-align="start center">
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">出库操作员：</div>
                    <div class="value" style="width:150px">{{viewdetails.out_emp_name}}</div>
                  </div>
                  <div class="item" layout="row" layout-align="start center" style="line-height:40px;color:#40404e">
                    <div class="label" style="width:150px;text-align:right">出库总成本：</div>
                    <div class="value" style="width:150px">{{viewdetails.total_amt}}</div>
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
                    <span class="reqfieldsd"></span>调拨单单号：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.code || '---'}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>入库仓库：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.in_store_name || '---'}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>出库仓库：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.out_store_name || '---'}}</div>
                </div>
              </div>
              <div class="tidsesfe">
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>入库时间：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.in_store_time || '---'}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>出库时间：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.out_store_time || '---'}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>入库操作员：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.in_emp_name || '---'}}</div>
                </div>
              </div>
              <div class="tidsesfe">
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>出库操作员：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.out_emp_name || '---'}}</div>
                </div>
                <div class="compatibility">
                  <div class="mandatory">
                    <span class="reqfieldsd"></span>出库总成本：
                  </div>
                  <div class="materialnr controlling">{{viewdetails.total_amt || '---'}}</div>
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
            </el-form> -->
            <div class="addmaterial" v-show="viewdetails.dtls != null">
              <div class="dindan">正常订单</div>
              <div class="juz">
                <table border style="border-collapse:collapse">
                  <thead>
                    <tr layout="row" layout-align="start center">
                      <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">序号</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">物料名称</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">物料分类</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">一级单位</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">二级单位</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">成本单价</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">数量</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">成本小计</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">状态</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr layout="row" layout-align="start center" v-for="(item,i) in viewdetails.dtls" :key="i" class="drag-list">
                      <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{i+1}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.n || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.moc || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.mtc || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.un || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{(item.a * 1 == 0 || item.c * 1 == 0) ? '0.00' : (item.a/item.c).toFixed(2)}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.c}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.a}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.s}}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <div class="addmaterial" v-show="viewdetails.yy_dtls != null">
              <div class="dindan">异议记录</div>
              <div class="juz">
                <table border style="border-collapse:collapse">
                  <thead >
                    <tr layout="row" layout-align="start center">
                      <th style="padding-left:4px;width:60px;text-align:left;line-height:40px">序号</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">物料名称</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">物料分类</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">一级单位</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">二级单位</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">确认数量</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">确认小计</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">异议数量</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">异议小计</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">异议备注</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">操作人</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">操作方</th>
                      <th style="padding-left:4px;width:80px;text-align:left;line-height:40px">操作时间</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr layout="row" layout-align="start center" v-for="(item,i) in viewdetails.yy_dtls" :key="i" class="drag-list">
                      <td style="padding-left:4px;width:60px;text-align:left;line-height:40px">{{i+1}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.n || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.moc || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.mtc || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.un || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.dc}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.da}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.yc}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.ya}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.r || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.oen || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.yo || '---'}}</td>
                      <td style="padding-left:4px;width:80px;text-align:left;line-height:40px">{{item.ot || '---'}}</td>
                    </tr>
                  </tbody>
                </table>
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
        <!-- </div> -->

        <span slot="footer" class="dialog-footer">
          <el-button @click="cfdetails = false">关闭</el-button>
          <!-- <el-button type="primary"  v-print="print">打印</el-button> -->
          <el-button type="primary" v-show="viewdetails.status == '已完成'||viewdetails.status == '待入库'" v-print="print">打印</el-button>
          <el-button type="primary" v-show="viewdetails.status == '已完成'" @click="xingh">申请售后</el-button>
          <el-button
            type="primary"
            v-show="viewdetails.status == '待入库'"
            @click="compileprinter"
          >确认入库</el-button>
          <el-button type="primary" v-show="viewdetails.status == '待入库'" @click="noneffective">部分入库</el-button>
          <el-button type="primary" v-show="viewdetails.status == '有异议'" @click="xingh">申请售后</el-button>
          <!-- <el-button type="primary" >确认</el-button>
          <el-button type="primary" >确认</el-button>-->
        </span>
      </el-dialog>
    </div>
    <!-- 申请售后 -->
    <div v-show="dialogible" class="dialogFormVisible">
      <el-dialog
        title="申请售后"
        :visible.sync="dialogible"
        @close="dialogible = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>调拨单单号：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.code || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>入库仓库：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.in_store_name || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库仓库：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.out_store_name || '---'}}</div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>入库时间：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.in_store_time || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库时间：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.out_store_time || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>入库操作员：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.in_emp_name || '---'}}</div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库操作员：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.out_emp_name || '---'}}</div>
            </div>
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>出库总售出金额：
              </div>
              <div class="materialnr controlling">{{ProductLibrary.sell_total_amt || '---'}}</div>
            </div>
          </div>
          <div class="tidsesfe">
            <div class="compatibility">
              <div class="mandatory">
                <span class="reqfieldsd"></span>备注：
              </div>
              <div class="materialnr gaib">{{ProductLibrary.remark || '---'}}</div>
            </div>
          </div>
        </el-form>
        <div class="materiafeflnrr" v-if="supplies">正常订单:</div>
        <div class="addmaterial" v-if="supplies">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>物料名称</th>
                <th>一级分类</th>
                <th>二级分类</th>
                <th>单位</th>
                <th>
                  <div class="alignment">成本单价</div>
                </th>
                <th>
                  <div class="alignment">入库数量</div>
                </th>
                <th>
                  <div class="alignment">成本小计</div>
                </th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody class="limiting">
              <tr v-for="(item,i) in supplies" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.moc || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.mtc || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.un || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <div class="alignment">{{(item.a/item.c).toFixed(2)}}</div>
                </td>
                <td>
                  <div class="alignment">{{item.c}}</div>
                </td>
                <td>
                  <div class="alignment">{{item.a}}</div>
                </td>
                <td>{{item.s}}</td>
                <td
                  v-if="item.s=='已完成'"
                  style="color: #438dfd;cursor:pointer;"
                  @click="objecrgtion(item)"
                >申请</td>
                <td v-else style="color: #434343;cursor:pointer;" @click="objecrgonssdsd">申请</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="materiafeflnrr" v-if="Objectionsingle">异议项</div>
        <div class="addmateriala" v-if="Objectionsingle">
          <table class="zhuixiaoi">
            <thead class="mmodity">
              <tr>
                <th>序号</th>
                <th>物料名称</th>
                <th>物料分类</th>
                <th>一级单位</th>
                <th>二级单位</th>
                <th>
                  <div class="alignment">确认数量</div>
                </th>
                <th>
                  <div class="alignment">确认小计</div>
                </th>
                <th>
                  <div class="alignment">异议数量</div>
                </th>
                <th>
                  <div class="alignment">异议小计</div>
                </th>
                <th>异议备注</th>
                <th>操作人</th>
                <th>操作方</th>
                <th>操作时间</th>
              </tr>
            </thead>
            <tbody class="limiting">
              <tr v-for="(item,i) in Objectionsingle" :key="i" class="drag-list">
                <td>{{i+1}}</td>
                <td>
                  <ellipsis-tooltip :text="item.n || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.moc || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.mtc || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.un || '---'"></ellipsis-tooltip>
                </td>
                <td>
                  <div class="alignment">{{item.dc}}</div>
                </td>
                <td>
                  <div class="alignment">{{item.da}}</div>
                </td>
                <td>
                  <div class="alignment">{{item.yc}}</div>
                </td>
                <td>
                  <div class="alignment">{{item.ya}}</div>
                </td>
                <td>
                  <ellipsis-tooltip :text="item.r || '---'"></ellipsis-tooltip>
                </td>
                <td>{{item.oen || '---'}}</td>
                <td>{{item.yo || '---'}}</td>
                <td>{{item.ot || '---'}}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <span slot="footer" class="dialog-footer">
          <el-button @click="dialogible = false">关闭</el-button>
          <!-- <el-button type="primary" @click="Applyaftsales">确认</el-button> -->
        </span>
      </el-dialog>
    </div>
    <!-- 有异议 -->
    <div v-show="objrgti" class="objecrgti">
      <el-dialog
        title="申请售后"
        :visible.sync="objrgti"
        @close="objrgti = false"
        :close-on-click-modal="false"
      >
        <el-form label-position="left">
          <div class="compatibility">
            <div class="mandatory" style="color: #40404e;">
              <span class="reqfieldsd"></span>原入库数量：
            </div>
            <div class="materialnr">{{objrgtion.c}}</div>
          </div>
          <div class="compatibility">
            <div class="mandatory" style="color: #40404e;">
              <span class="reqfieldsd">*</span>异议数量：
            </div>
            <div class="controlling">
              <el-input v-model="objrgtion.sl" placeholder="请输出异议数量" class="altersl" />
            </div>
          </div>
          <div class="compatibility">
            <div class="mandatory" style="color: #40404e;">
              <span class="reqfieldsd">*</span>异议原因：
            </div>
            <el-input
              class="controlling"
              type="textarea"
              v-model="objrgtion.remark"
              :rows="3"
              placeholder="请输入异议原因"
              show-word-limit
              :class="form_rule_msg_remark?'error':''"
              @blur="validator('remark')"
            />
            <div class="cwts">{{form_rule_msg_remark}}</div>
          </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button @click="objrgti = false">关闭</el-button>
          <el-button type="primary" @click="Applyaftsales">确认</el-button>
        </span>
      </el-dialog>
    </div>
  </div>
</template>
<script>
import EllipsisTooltip from "@/components/EllipsisTooltip.vue"; //根据路径导入组件
import CharactersButton from "@/components/CharactersButton.vue"; //根据路径导入组件
export default {
  data() {
    return {
      Inbound: {
        date: [], //日期
        state: "0", //类型
        pagenum: 1, //当前页数
        pagecnt: 1, //总页数
        rowcnt: 1, //总行数
        cklx: "", //出库仓库
        init: 1 //是否初始化
      }, //出库
      jindst: "1", //近多少天
      cklxnr: [], //出库仓库
      tableData: [], // 读取管理列表
      dialogFormVisible: false, //控制新建出库是否显示
      ProductLibrary: {}, //出库
      supplies: [], //正常入库列表
      addprincipal: false, //控制添加物料是否显示
      applyforyy: {}, //申请异议
      Objectionsingle: [], //异议单
      multipleSelection: [], // 选中的内容
      isIndeterminate: false, // 出库选择一部分
      checkAll: false, //出库全选
      viewdetails: {}, //查看详情内容
      cfdetails: false, // 控制查看详情显示与否
      dialogible: false, //控制申请售后是否显示

      print: {
        id: "print",
        popTitle: "其他入库单" // 打印配置页上方标题
        // extraHead: '调拨入库单',
      },
      objrgtion: {}, //有异议
      objrgti: false,
      windowWidt: document.documentElement.clientWidth, //实时屏幕宽度
      windowHeigh: document.documentElement.clientHeight, //实时屏幕高度
      MaxHeight: 0, //滚动高度
      MaxNumber: 0, //最大个数

      form_rules: ["remark"],
      form_rule_msg_remark: "",

      flag: false
    };
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
  computed: {},
  filters: {
    decimal(v) {
      // console.log(v);
      return v.toFixed(2);
    }
  },
  components: {
    EllipsisTooltip,
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
          if (this.$overall.character(this.objrgtion.remark) > 280) {
            this.form_rule_msg_remark = "输入文字长度超过140";
          } else {
            this.form_rule_msg_remark = "";
          }
          break;
      }
    },
    // 滚动最大高度
    RollMaxHeight(i) {
      var g = document.getElementsByClassName("sind-rkrq")[0].clientHeight;
      var s = i - 48 - 60 - 55 - 70 - 70 - g;
      this.MaxHeight = s;
      this.MaxNumber = Math.floor(s / 37);
      console.log(this.MaxNumber);
      // console.log(i);
    },
    // 打印
    Print() {
      console.log(1111)
      myPrint(this.$refs.print);
      function myPrint(obj) {
        newWindow.print();
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
      this.$api.ERP.sind
        .requestsindlist({
          page_num: this.Inbound.pagenum,
          page_size: 10,
          status: Number(this.Inbound.state),
          begin_day: this.Inbound.date[0],
          end_day: this.Inbound.date[1],
          is_init: this.Inbound.init,
          out_store_id: Number(this.Inbound.cklx) || 0
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.tableData = res.data.datas || [];
            this.Inbound.pagecnt = res.data.page_cnt;
            this.Inbound.rowcnt = res.data.row_cnt;
            this.Inbound.pagenum = res.data.page_num;
            this.cklxnr = res.data.stores;
            this.multipleSelection = [];
            this.isIndeterminate = false;
            this.checkAll = false;
          } else {
            this.$message.warning(res.msg);
          }
        });
    },
    // 查询
    cdemand() {
      this.Inbound.pagenum = 1;
      this.demand();
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
      // console.log(value);
      let checkedCount = value.length;
      this.checkAll = checkedCount === this.tableData.length;
      this.isIndeterminate =
        checkedCount > 0 && checkedCount < this.tableData.length;
      // console.log(this.checkedCities);
    },
    // 当前是多少页
    handleCurrentChange(val) {
      // console.log(`当前页: ${val}`);
      this.Inbound.pagenum = val;
      this.demand();
    },
    // 重置
    resetstorage() {
      this.Inbound.date = [];
      this.Inbound.state = "3";
      this.Inbound.pagenum = 1;
      this.Inbound.pagecnt = 1;
      this.Inbound.rowcnt = 1;
      this.Inbound.cklx = "";
      this.tableData = [];
      this.jindst = "1";
      this.daterq();
      this.demand();
    },
    // 打开部分入库
    noneffective() {
      this.cfdetails = false;
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sind
          .requestsindget_f_pt({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.dialogFormVisible = true;
              this.ProductLibrary = res.data;
              this.supplies = res.data.dtls;

              this.edit();
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message.warning("请选择一个进行操作");
      }
    },
    // 部分入库确认提交
    construction() {
      // console.log(this.supplies);
      var s = {
        dtl_ids: [],
        yy_dtl_ids: [],
        in_cnts: [],
        yy_remarks: []
      };
      for (const iterator of this.supplies) {
        // console.log(iterator.sl);
        if (iterator.sl == iterator.c) {
          s.dtl_ids.push(iterator.id);
        } else {
          console.log(iterator.sl);
          if (iterator.sl === undefined) {
            s.in_cnts.push("");
          } else {
            s.in_cnts.push(Number(iterator.sl));
          }
          s.yy_dtl_ids.push(iterator.id);
          s.yy_remarks.push(iterator.remark || "");
        }
      }
      console.log(s);
      // var w = true
      // for (const key in s.yy_remarks) {
      //     console.log(s.yy_remarks[key] == '');
      //     if(s.yy_remarks[key] == ''){
      //         w = false
      //     }
      // }
      // console.log(w);
      // if(w){
      //     this.$message({
      //         message: '确认数量小于待确认数量时异议原因必填 ',
      //         type: 'warning'
      //     });
      // }else{
      var sss = true;
      for (const key in s.in_cnts) {
        console.log(s.in_cnts[key]);
        console.log(s.in_cnts[key] === "");
        if (s.in_cnts[key] === "") {
          this.$message({
            message: "请填写确认数量",
            type: "warning"
          });
          sss = false;
          console.log(key);
          // this.$nextTick(()=>{  //次要代码
          //   this.$refs.selectsse[key].focus();
          //   console.log(this.$refs);
          // })
          break;
        } else {
          if (s.yy_remarks[key] === "") {
            // this.$nextTick(()=>{  //次要代码
            // this.$refs.seltsse[key].focus();
            // })
            this.$message({
              message: "请填写异议原因 ",
              type: "warning"
            });
            sss = false;
            break;
          }
        }
      }

      console.log(sss);
      // seltsse
      if (sss) {
        this.$api.ERP.sind
          .requestsindone_part_in({
            id: this.multipleSelection[0],
            dtl_ids: s.dtl_ids,
            yy_dtl_ids: s.yy_dtl_ids,
            in_cnts: s.in_cnts,
            yy_remarks: s.yy_remarks
          })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
              this.dialogFormVisible = false;
              this.demand();
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
      // }
    },
    // 批量入库 调拨入库，确认入库
    compileprinter() {
      console.log(this.multipleSelection);
      if (this.multipleSelection.length != 0) {
        this.$api.ERP.sind
          .requestsindbatch_in({ ids: this.multipleSelection })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.cfdetails = false;
              this.demand();
              this.$message({
                showClose: true,
                message: "操作成功",
                type: "success"
              });
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "最少选择一个进行操作",
          type: "warning"
        });
      }
    },
    // 读取调拨入库单详情, 用于信息展示
    showviewdetails(id) {
      this.multipleSelection = [id];
      this.isIndeterminate = true;
      console.log(id);
      this.$api.ERP.sind.requestsindget_f_view({ id: id }).then(res => {
        console.log(res.data);
        if (res.code == 1) {
          this.viewdetails = res.data || {};
          this.cfdetails = true;
        } else {
          this.$message.warning(res.msg);
        }
      });
    },
    // 打开申请售后
    xingh() {
      this.cfdetails = false;
      for(let i = 0; i< this.multipleSelection.length; i++){
        const find = this.tableData.find(item => item.id == this.multipleSelection[i])
        if(!(find && find.s == '已完成')) {
          this.$message.warning('申请售后只可操作已完成订单')
          return
        }
      }
      if (this.multipleSelection.length == 1) {
        this.$api.ERP.sind
          .requestsindget_f_sh({ id: this.multipleSelection[0] })
          .then(res => {
            console.log(res);
            if (res.code == 1) {
              this.dialogible = true;
              this.ProductLibrary = res.data;
              this.supplies = res.data.dtls;
              this.Objectionsingle = res.data.yy_dtls;
              // this.edit()
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "请先选择一个单子再进行操作",
          type: "warning"
        });
      }
    },
    //获取焦点
    edit() {
      this.$nextTick(() => {
        //次要代码
        this.$refs.selectsse[0].focus();
        console.log(this.$refs);
      });
    },
    // 有异议
    objecrgtion(item) {
      console.log(item);
      this.form_rule_msg_remark = "";
      this.objrgtion = [];
      this.objrgtion = item;
      this.objrgti = true;
    },
    // !有异议
    objecrgonssdsd() {
      this.$message.warning("只有已完成状态,才能申请");
    },
    // 申请售后
    Applyaftsales() {
      this.form_rules.map(item => this.validator(item));
      if (this.form_rule_msg_remark) return;
      this.$api.ERP.sind
        .requestsindsh({
          id: this.objrgtion.id,
          yy_cnt: Number(this.objrgtion.sl),
          remark: this.objrgtion.remark || "---"
        })
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            this.objrgti = false;
            this.xingh();
            this.$message({
              showClose: true,
              message: "操作成功",
              type: "success"
            });
          } else {
            this.$message.warning(res.msg);
          }
        });
    },

    // 部分入库数量确认与异议备注的关系
    clearRemarkHandle(itemInfo) {
      if (itemInfo.c == itemInfo.sl) {
        itemInfo.remark = ""
      }
      itemInfo.disabled = itemInfo.c == itemInfo.sl
    }
  },
  computed: {
    suppliess() {
      return JSON.parse(JSON.stringify(this.supplies));
    },
    Inboundstate() {
      return JSON.parse(JSON.stringify(this.Inbound.state));
    },
    objrgtionsss() {
      return JSON.parse(JSON.stringify(this.objrgtion));
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
    // 只能输入数字
    suppliess: {
      deep: true,
      handler: function(after, before) {
        for (const key in after) {
          if (after[key].sl) {
            if (after[key].sl != before[key].sl) {
              var reg = /^[0-9]*$/g;
              if (reg.test(after[key].sl)) {
                if (after[key].sl > after[key].c) {
                  this.supplies[key].sl = after[key].c + "";
                }
              } else {
                this.supplies[key].sl = (before[key].sl || "") + "";
              }
            }
          }
        }
      }
    },
    Inboundstate: {
      deep: true,
      handler: function(after, before) {
        // console.log(after);
        this.demand();
      }
    },
    // 有异议
    objrgtionsss: {
      deep: true,
      handler: function(after, before) {
        if (after.sl > after.c) {
          this.$message({
            message: "异议数量不得超过原入库数量",
            type: "warning"
          });
          this.objrgtion.sl = before.c;
        }
      }
    }
  }
};
</script>
<style>
/* 靠右 */
.sind .el-dialog {
  margin: 0px 0px 0px auto !important;
  background-color: #f9f9f9;
  height: 100%;
  position: relative;
}

.sind .el-dialog__footer {
  position: absolute;
  width: 100%;
  bottom: 0;
  right: 0;
  display: flex;
  justify-content: center;
}

.sind .el-dialog__body {
  padding: 0px 20px 30px 20px;
  overflow-y: scroll !important;
  width: calc(100% - 40px);
  height: calc(100% - 160px);
  max-height: calc(100% - 160px);
  margin: 0;
}

.sind .el-dialog {
  box-shadow: 0px 0px 20px 8px rgba(0, 0, 0, 0.1);
}

.sind {
  width: calc(100% - 40px);
  height: calc(100% - 40px);
  padding: 20px 30px;
}

.sind .gaib {
  width: 500px !important;
  display: flex;
  align-items: center;
}

/* 必填 */
.sind .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
  line-height: 40px;
  /* padding-top: 10px; */
}

.sind .controlling {
  width: 230px !important;
  line-height: 40px;
}

.sind .reqfieldsd {
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
.sind .tiaodd {
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

.sind .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 0;
}

.sind .nodata img {
  width: 60px;
  height: 60px;
}

.sind .nodata .hint {
  line-height: 36px;
  font-size: 13px !important;
}

.sind .drag-list .nodata {
  width: 100% !important;
  height: 250px !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.sind .drag-list .nodata img {
  width: 60px;
  height: 60px;
}

.sind .drag-list .nodata .hint {
  font-size: 13px !important;
}

/* 表格内文字居中 */
.sind .alignment {
  text-align: right !important;
  padding-right: 15px;
}

.sind .Writmiddle .el-input__inner {
  text-align: right;
}

.sind .Writmiddle .el-input__inner::-webkit-input-placeholder {
  text-align: center;
}

/* 全选字体大小 */
.sind .zhuixiaoi .mmodity .el-checkbox__label {
  font-size: 12px;
}

/* 给一级分类二级分类加外边距和圆角 */
.sind .el-radio-button {
  margin-right: 6px;
  margin-bottom: 6px;
  /* overflow: hidden; */
  /* border: 1px solid #f5f5f5; */
}

.sind .el-radio-button__inner {
  border-radius: 4px !important;
}

.sind .container .el-radio-button__inner {
  padding: 6px 20px;
}

/* 去除瑕疵 */
.sind .el-radio-button__orig-radio:checked + .el-radio-button__inner {
  box-shadow: none;
}

/* 选中状态颜色背景边框 */
.sind .el-radio-button__orig-radio:checked + .el-radio-button__inner {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #2170ff !important;
  color: #2170ff;
}

/* 内容 */
.sind .sind-headline {
  font-size: 30px;
  font-weight: bold;
  color: #40404e;
}

.sind .sind-controller {
  height: 54px;
  background-color: #e5e5e5;
  display: flex;
  align-items: center;
}

.sind .sind-rkrq {
  width: 100%;
  color: #40404e;
  overflow: hidden;
  font-size: 13px;
  line-height: 14px;
}

.sind .sind-rkrq .rkrq {
  display: inline-flex;
  align-items: center;
  margin: 0 0 14px 0;
}

.sind .sind-rkrq .rkrq:nth-child(1) {
  width: 670px !important;
}

.sind .sind-rkrq .rkrq:nth-child(2) {
  width: 275px !important;
}

.sind .sind-rkrq .rkrq:nth-child(3) {
  width: 150px !important;
}

.sind .sind-rkrq .rkrq .danxk {
  height: 34px;
  margin-right: 10px;
  display: inline-flex;
  align-items: center;
}

.sind .sind-rkrq .rkrq .danxk img {
  display: inline-block;
  width: 12px;
  height: 12px;
  margin-right: 6px;
}

.sind .sind-rkrq .rkrq .danxk .el-radio-button {
  margin: 0px 4px;
  box-shadow: none !important;
}

.sind .sind-rkrq .rkrq .danxk .el-radio-button__inner {
  border-radius: 19px !important;
  border: 0px !important;
  color: #40404e;
  font-size: 12px;
  display: flex;
  align-items: center;
  line-height: 16px;
  padding: 5px 15px;
}

.sind
  .sind-rkrq
  .rkrq
  .danxk
  .el-radio-button__orig-radio:checked
  + .el-radio-button__inner {
  color: #2170ff;
}

.sind .ewdetai {
  color: #2170ff;
  cursor: pointer;
}

.sind .layouts {
  margin-left: 20px;
  padding-top: 5px;
  font-size: 13px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.sind .AddPrincipal {
  color: #4eadfc;
}

.sind .compatibility {
  display: flex;
  align-items: center;
  /* margin-bottom: 10px; */
}

.sind .required {
  width: 60px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

/* 取消按钮 */
.sind .el-dialog .el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
}

.sind .el-dialog {
  background-color: #f9f9f9;
}

.sind .el-input__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
  height: 30px;
  line-height: 30px;
}

.sind .el-dialog__title,
.sind .el-dialog__headerbtn .el-dialog__close,
.sind .el-form-item__label {
  color: #1a1a21;
}

.sind .el-input {
  /* width: 190px; */
}

.sind .el-form-item {
  display: flex;
  margin: 0;
}

/* 改变多选框背景颜色和上下间距 */
.sind .el-checkbox-group {
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.sind .el-checkbox {
  height: 37px !important;
}

.sind .el-checkbox__input {
  background-color: rgba(0, 0, 0, 0);
}

.sind .el-dialog {
  width: 30vw;
}

.sind .has-gutter {
  border: 1px solid #f5f5f5;
}

.sind table thead tr th,
.sind table tbody tr td {
  height: 40px;
  font-size: 14px;
}

/* 一级分类和二级分类文字颜色更改 */
.sind .stairfl {
  display: flex;
  align-items: center;
  margin: 0 0 14px 0;
  font-size: 13px;
  line-height: 14px;
}

.sind .stairfl .classification {
  color: #40404e;
  margin-right: 3px;
  /* font-size: 14px; */
  padding-top: 0px;
}

.sind .stairfl .stairastrict {
  height: 34px;
  display: flex;
  align-items: center;
}

.sind .stairfl .container {
  height: 30px;
}

/* 更改单选框颜色 */
.sind .el-radio-button__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
  border: 1px solid #f5f5f5;
  font-size: 14px;
  height: 30px;
}

.sind .el-radio-button:first-child .el-radio-button__inner {
  border-left: 1px solid #f5f5f5;
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

.xdownbox {
  display: none;
}

/* 新增仓库 */
.sind .el-tag {
  background-color: rgba(0, 0, 0, 0);
  margin-right: 10px;
  margin-bottom: 10px;
  color: #40404e;
}

.sind .el-tag i {
  color: #40404e;
}

.sind .tidsesfe {
  display: flex;
}

/* 多行文本输出框 */
.sind .el-textarea__inner {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
  width: 100%;
}

.sind .el-input__count {
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
.sind .dialogFormVisible .el-dialog {
  width: 1280px;
}

.sind .dialogFormVisible .el-form {
  padding: 0px;
  margin: 20px;
  background-color: #f5f5f5;
  border: 1px solid #f5f5f5;
  border-radius: 8px;
}

.sind .addmaterial {
  margin-left: 20px;
  margin-bottom: 20px;
  max-width: 1180px;
  overflow-x: scroll;
  padding-top: 20px;
}

.sind .addmaterial .limiting {
  /* max-height: 400px;
        overflow-y: scroll; */
}

.sind .materialnr {
  /* padding-top: 10px;
        margin-left: 20px; */
  color: #40404e;
}

.sind .dialogFormVisible .zhuixiaoi {
  width: auto;
}

.sind .dialogFormVisible .materiafeflnrr {
  color: #40404e;
  margin-left: 20px;
  font-size: 18px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(2),
.sind .dialogFormVisible .mmodity th:nth-of-type(2) {
  width: 250px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(3),
.sind .dialogFormVisible .mmodity th:nth-of-type(3) {
  width: 130px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(4),
.sind .dialogFormVisible .mmodity th:nth-of-type(4) {
  width: 130px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(5),
.sind .dialogFormVisible .mmodity th:nth-of-type(5) {
  width: 100px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(6),
.sind .dialogFormVisible .mmodity th:nth-of-type(6) {
  width: 100px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(7),
.sind .dialogFormVisible .mmodity th:nth-of-type(7) {
  width: 100px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(8),
.sind .dialogFormVisible .mmodity th:nth-of-type(8) {
  width: 110px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(9),
.sind .dialogFormVisible .mmodity th:nth-of-type(9) {
  width: 100px;
}

.sind .dialogFormVisible .drag-list td:nth-of-type(10),
.sind .dialogFormVisible .mmodity th:nth-of-type(10) {
  width: 100px;
}

.sind .addmateriala {
  /* margin-top: 20px; */
  padding-top: 10px;
  /* border-top:2px solid #443f3f; */
}

.sind .materialnr {
  color: #40404e;
}

.sind .dialogFormVisible .addmateriala {
  margin-left: 20px;
  max-width: 1180px;
  overflow-x: scroll;
  padding-top: 20px;
}

.sind .dialogFormVisible .addmateriala .limiting {
  max-height: 400px;
  overflow-y: scroll;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(2),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(2) {
  width: 250px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(3),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(3) {
  width: 130px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(4),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(4) {
  width: 130px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(5),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(5) {
  width: 90px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(6),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(6) {
  width: 90px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(7),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(7) {
  width: 100px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(8),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(8) {
  width: 100px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(9),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(9) {
  width: 100px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(10),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(10) {
  width: 100px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(11),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(11) {
  width: 100px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(12),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(12) {
  width: 130px;
}

.sind .dialogFormVisible .addmateriala .drag-list td:nth-of-type(13),
.sind .dialogFormVisible .addmateriala .mmodity th:nth-of-type(13) {
  width: 120px;
}

.sind .dialogFormVisible .el-input-number {
  width: 100%;
}

/* 申请售后 */
.sind .objecrgti .el-dialog {
  width: 500px;
}

.sind .objecrgti .compatibility {
  margin-bottom: 10px;
}

.sind .objecrgti .controlling {
  width: 230px !important;
  line-height: 40px;
}

/* 查看 */
.sind .viewdetailscls .el-dialog {
  width: 1280px;
  /* width: 80vw !important; */
  /* min-width: 520px !important;
        max-width:540px !important; */
}

.sind .viewdetailscls .el-form {
  padding: 0px;
  margin: 20px;
  background-color: #eee;
  border-radius: 8px;
}

.sind .viewdetailscls .zhuixiaoi {
  width: auto;
}

.sind .viewdetailscls .addmaterial .dindan {
  color: #40404e;
  font-size: 14px;
  margin-bottom: 10px;
}

.sind .monad,
.sind .show {
  display: none;
}

.sind .viewdetailscls .materialnr {
  width: 200px;
}

.sind .viewdetailscls .materialnrs {
  width: 600px;
}

.sind .viewdetailscls .materialnr,
.sind .viewdetailscls label,
.sind .viewdetailscls .materialnrs {
  color: #40404e;
  font-size: 14px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(2),
.sind .viewdetailscls .mmodity th:nth-of-type(2) {
  width: 250px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(3),
.sind .viewdetailscls .mmodity th:nth-of-type(3) {
  width: 130px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(4),
.sind .viewdetailscls .mmodity th:nth-of-type(4) {
  width: 130px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(5),
.sind .viewdetailscls .mmodity th:nth-of-type(5) {
  width: 100px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(6),
.sind .viewdetailscls .mmodity th:nth-of-type(6) {
  width: 100px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(7),
.sind .viewdetailscls .mmodity th:nth-of-type(7) {
  width: 100px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(8),
.sind .viewdetailscls .mmodity th:nth-of-type(8) {
  width: 100px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(9),
.sind .viewdetailscls .mmodity th:nth-of-type(9) {
  width: 100px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(10),
.sind .viewdetailscls .mmodity th:nth-of-type(10) {
  width: 100px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(11),
.sind .viewdetailscls .mmodity th:nth-of-type(11) {
  width: 130px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(12),
.sind .viewdetailscls .mmodity th:nth-of-type(12) {
  width: 130px;
}

.sind .viewdetailscls .drag-list td:nth-of-type(13),
.sind .viewdetailscls .mmodity th:nth-of-type(13) {
  width: 130px;
}

/* 添加物料 */
/* 模糊查询 */
.sind .search .el-dialog {
  width: 450px;
  /* width: 50vw !important;
        min-width: 550px !important;
        max-width:560px !important; */
}

/* 物料信息 */
.sind .search .materialsoutformation {
  margin-top: 20px;
  padding-top: 10px;
  /* border-top:2px solid rgb(88, 88, 88) ; */
}

.sind .search .materialsoutformation .information {
  color: #40404e;
  font-size: 14px;
  margin-bottom: 12px;
}

.sind .search .materialsoutformation .materialnr {
  color: #40404e;
}

.sind .search .materialsoutformation .protyfsfg {
  margin: 0 0 10px;
  color: #40404e;
  width: 360px;
  display: flex;
  justify-content: space-between;
}

.sind .search .materialsoutformation .protyfsfg input {
  width: 230px;
}

.sind .search .zhuixiaoi .limiting .drag-list td {
  /* height: 14px;
        line-height: 20px;
        padding: 23px 0; */
  line-height: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  line-height: none;
}

.sind .search .el-input-number {
  width: 100%;
}

.sind .search .drag-list td:nth-of-type(2),
.sind .search .mmodity th:nth-of-type(2) {
  width: 300px;
}

.sind .search .drag-list td:nth-of-type(3),
.sind .search .mmodity th:nth-of-type(3) {
  width: 90px;
}

.sind .search .drag-list td:nth-of-type(4),
.sind .search .mmodity th:nth-of-type(4) {
  width: 90px;
}

.sind .search .drag-list td:nth-of-type(5),
.sind .search .mmodity th:nth-of-type(5) {
  width: 150px;
}

/* 字体不居中 */
.sind .search .el-input-number .el-input__inner {
  text-align: left;
}

/* 仓库列表 */
.zsykd {
  width: 100%;
  overflow-x: scroll !important;
}

.sind .zhuixiaoi {
  width: 1600px;
  overflow: hidden;
  border-collapse: collapse;
  color: #40404e;
}

.sind .zhuixiaoi .mmodity tr th {
  height: 36px;
  line-height: 36px;
  text-align: left;
  font-weight: 600;
  color: #40404e;
  padding-left: 20px;
}
.sind .zhuixiaoi .mmodity tr th .el-checkbox__label {
    font-size: 14px;
    font-weight: 600;
    color: #40404e;
}

.sind .zhuixiaoi .limiting .drag-list td {
  height: 36px;
  line-height: 36px;
  text-align: left;
  white-space: normal;
  word-break: break-all;
  padding-left: 20px;
}

.sind .zhuixiaoi .limiting .drag-list {
  display: block;
  /* width: calc(100% - 17px); */
  display: flex;
  border-top: solid 1px #f5f5f5;
}

.sind .zhuixiaoi .mmodity {
  width: 100%;
  display: block;
}

.sind .zhuixiaoi .mmodity tr {
  background-color: #f5f5f5;
  display: flex;
}

.sind .zhuixiaoi .limiting {
  border-bottom: solid 1px #f5f5f5;
  overflow-y: auto !important;
  max-height: 540px;
  display: block;
}

.sind .drag-list td:nth-of-type(1),
.sind .mmodity th:nth-of-type(1) {
  width: 70px;
}

.sind .mmodity th:nth-of-type(2),
.sind .drag-list td:nth-of-type(2) {
  width: 150px;
  /* display:inline-block;
        width:calc(100% - 840px); */
  /* width: 100%; */
}

.sind .drag-list td:nth-of-type(3),
.sind .mmodity th:nth-of-type(3) {
  width: 130px;
}

.sind .drag-list td:nth-of-type(4),
.sind .mmodity th:nth-of-type(4) {
  width: 140px;
}

.sind .drag-list td:nth-of-type(5),
.sind .mmodity th:nth-of-type(5) {
  width: 120px;
}

.sind .drag-list td:nth-of-type(6),
.sind .mmodity th:nth-of-type(6) {
  width: 140px;
}

.sind .drag-list td:nth-of-type(7),
.sind .mmodity th:nth-of-type(7) {
  width: 140px;
}

.sind .drag-list td:nth-of-type(8),
.sind .mmodity th:nth-of-type(8) {
  width: 140px;
}

.sind .drag-list td:nth-of-type(9),
.sind .mmodity th:nth-of-type(9) {
  width: 130px;
}

.sind .drag-list td:nth-of-type(10),
.sind .mmodity th:nth-of-type(10) {
  width: 150px;
}

.sind .drag-list:nth-of-type(odd) {
  background-color: #f9f9f9;
  color: #40404e;
}

.sind .drag-list:nth-of-type(even) {
  background-color: #f5f5f5;
  color: #40404e;
}

.sind .zhuixiaoi .el-checkbox__label {
  color: #40404e;
  /* font-size: 12px; */
}

/*  */
.sind .zhuixiaoi .chaoguogai {
  height: 20px;
  /* text-align: center; */
  line-height: 20px;
  width: 136px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 日期选择器 */
.sind .sind-rkrq .rkrq .el-range-editor .el-range-input {
  background-color: rgba(0, 0, 0, 0);
  color: #40404e;
}

.sind .sind-rkrq .rkrq .el-date-editor .el-range-separator,
.sind .sind-rkrq .rkrq .el-date-editor .el-range__icon {
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
  color: #40404e;
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
.sind .Pagination {
  /* width: 1093px; */
  text-align: right;
  margin-top: 20px;
}

.sind .Pagination .el-pagination.is-background .btn-next,
.sind .Pagination .el-pagination.is-background .btn-prev,
.sind .Pagination .el-pagination.is-background .el-pager li {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
  color: #40404e;
}

.sind .Pagination .btn-prev {
  background-color: rgba(0, 0, 0, 0);
  border: 1px solid #606266;
}

.sind .Pagination .el-pagination {
  padding: 0;
}

.sind .Pagination .el-pagination .btn-next .el-icon,
.sind .Pagination .el-pagination .btn-prev .el-icon {
  color: #40404e;
}

.sind
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
  size: auto;
  margin: 5mm;
  /* width: 100%;
        height: 100%; */
}

@media print {
  html {
    /* margin-left: 30px; */
    /* width: 100%;
            height: 100%; */
  }

  .printsind .show {
    display: block;
  }

  .printsind .monad {
    font-weight: bold;
    display: block;
    font-size: 30px;
    margin-top: 50px;
    color: #000;
    text-align: center;
  }

  .printsind .tidsesfe {
    display: flex;
  }

  .printsind .compatibility {
    display: flex;
    align-items: center;
  }

  .printsind .mandatory {
    color: #000;
    width: 140px;
    text-align: right;
    /* padding-top: 10px; */
  }

  .printsind .controlling {
    width: 370px !important;
    line-height: 40px;
  }

  .printsind .reqfieldsd {
    font-size: 16px;
    padding-right: 4px;
    color: #ce4153;
    /* 文字不可选中 */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .printsind .zhuixiaoi {
    overflow: hidden;
    border-collapse: collapse;
    color: #000;
  }

  .printsind .zhuixiaoi .mmodity tr th {
    height: 40px;
    line-height: 40px;
    text-align: center;
    /* border: solid 1px #f5f5f5; */
    border-top: solid 1px #f5f5f5;
    border-right: solid 1px #f5f5f5;
    border-bottom: solid 1px #f5f5f5;
    background-color: #2d2e38;
    font-weight: 400;
  }

  .printsind .zhuixiaoi .mmodity th:nth-of-type(1) {
    border-left: solid 1px #f5f5f5;
  }

  .printsind .zhuixiaoi .limiting .drag-list td {
    height: 40px;
    line-height: 40px;
    text-align: center;
    white-space: normal;
    word-break: break-all;
    /* border: solid 1px #f5f5f5; */
    border-bottom: solid 1px #f5f5f5;
    border-right: solid 1px #f5f5f5;
  }

  .printsind .zhuixiaoi .limiting .drag-list td:nth-of-type(1) {
    border-left: solid 1px #f5f5f5;
  }

  .printsind .zhuixiaoi .limiting .drag-list {
    display: block;
    display: flex;
  }

  .printsind .zhuixiaoi .mmodity {
    width: 100%;
    display: block;
  }

  .printsind .zhuixiaoi .mmodity tr {
    display: flex;
  }

  .printsind .el-form-item {
    display: flex;
    margin: 0;
  }

  .printsind .el-dialog {
    width: 1100px;
  }

  .printsind .juz {
    margin-left: 20px;
  }

  .printsind .addmaterial .dindan {
    color: #000;
    font-size: 20px;
    margin-bottom: 20px;
  }

  .printsind .materialnr {
    width: 200px;
  }

  .printsind .materialnrs {
    width: 600px;
  }

  .printsind .materialnr,
  .printsind label,
  .printsind .materialnrs {
    color: #000;
    font-size: 14px;
  }

  .printsind .drag-list td:nth-of-type(1),
  .printsind .mmodity th:nth-of-type(1) {
    width: 70px;
  }

  .printsind .drag-list td:nth-of-type(2),
  .printsind .mmodity th:nth-of-type(2) {
    width: 250px;
  }

  .printsind .drag-list td:nth-of-type(3),
  .printsind .mmodity th:nth-of-type(3) {
    width: 180px;
  }

  .printsind .drag-list td:nth-of-type(4),
  .printsind .mmodity th:nth-of-type(4) {
    width: 75px;
  }

  .printsind .drag-list td:nth-of-type(5),
  .printsind .mmodity th:nth-of-type(5) {
    width: 80px;
  }

  .printsind .drag-list td:nth-of-type(6),
  .printsind .mmodity th:nth-of-type(6) {
    width: 80px;
  }

  .printsind .drag-list td:nth-of-type(7),
  .printsind .mmodity th:nth-of-type(7) {
    width: 80px;
  }

  .printsind .drag-list td:nth-of-type(8),
  .printsind .mmodity th:nth-of-type(8) {
    width: 180px;
  }

  .printsind .signature {
    display: flex;
    margin-top: 50px;
  }

  .printsind .signature > div {
    margin-left: 30px;
    display: flex;
  }

  .printsind .signature span {
    font-size: 20px;
  }

  .printsind .signature .xian {
    width: 180px;
    height: 30px;
    border-bottom: 1px solid #000;
  }
}

.el-input__icon {
  line-height: 30px;
}

.out_sum .el-input {
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

.drag-list-check {
  /* background: rgba(39, 52, 82, 0.5) !important; */
}
</style>