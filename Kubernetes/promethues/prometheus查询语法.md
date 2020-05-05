[TOC]



# Prometheus查询

PromQL（Prometheus Query Language）是 Prometheus 自己开发的表达式语言，语言表现力很丰富，内置函数也很多。使用它可以对时序数据进行筛选和聚合。





## 1. PromQL 语法

### 1.1 数据类型

PromQL 表达式计算出来的值有以下几种类型：

- 瞬时向量 (Instant vector): 一组时序，每个时序只有一个采样值
- 区间向量 (Range vector): 一组时序，每个时序包含一段时间内的多个采样值
- 标量数据 (Scalar): 一个浮点数
- 字符串 (String): 一个字符串，暂时未用

### 1.2 时序选择器

#### 1.2.1 瞬时向量选择器

瞬时向量选择器用来选择**一组时序在某个采样点的采样值**。

最简单的情况就是指定一个度量指标，选择出所有属于该度量指标的时序的当前采样值。比如下面的表达式：

```
http_requests_total
```

可以通过在后面添加用大括号包围起来的一组标签键值对来对时序进行过滤。比如下面的表达式筛选出了 `job` 为 `prometheus`，并且 `group` 为 `canary` 的时序：

```
http_requests_total{job="prometheus", group="canary"}
```



匹配标签值时可以是**等于**，也可以**使用正则表达式**。总共有下面几种匹配操作符：

- `=`：完全相等
- `!=`： 不相等
- `=~`： 正则表达式匹配
- `!~`： 正则表达式不匹配



下面的表达式筛选出了 environment 为 staging 或 testing 或 development，并且 method 不是 GET 的时序：

```
http_requests_total{environment=~"staging|testing|development",method!="GET"}
```

度量指标名可以使用内部标签 `__name__` 来匹配，表达式 `http_requests_total` 也可以写成 `{__name__="http_requests_total"}`。表达式 `{__name__=~"job:.*"}` 匹配所有度量指标名称以 `job:` 打头的时序。



#### 1.2.2 区间向量选择器

区间向量选择器类似于瞬时向量选择器，不同的是它选择的是**过去一段时间的采样值**。可以通过在瞬时向量选择器后面添加包含在 `[]` 里的时长来得到区间向量选择器。比如下面的表达式选出了所有度量指标为 `http_requests_total` 且 `job` 为 `prometheus` 的时序在过去 5 分钟的采样值。

```
http_requests_total{job="prometheus"}[5m]
```

**说明：时长的单位可以是下面几种之一：**

- s：seconds
- m：minutes
- h：hours
- d：days
- w：weeks
- y：years



#### 1.2.3 偏移修饰器

前面介绍的选择器默认都是以当前时间为基准时间，偏移修饰器用来调整基准时间，使其往前偏移一段时间。偏移修饰器紧跟在选择器后面，使用 offset 来指定要偏移的量。比如下面的表达式选择度量名称为 `http_requests_total` 的所有时序在 `5` 分钟前的采样值。

```
http_requests_total offset 5m
```

下面的表达式选择 `http_requests_total` 度量指标在 `1` 周前的这个时间点过去 5 分钟的采样值。

```
http_requests_total[5m] offset 1w
```

## 2. PromQL 操作符

### 2.1 二元操作符

PromQL 的二元操作符支持基本的逻辑和算术运算，包含**算术类**、**比较类**和**逻辑类**三大类。

#### 2.1.1 算术类二元操作符

算术类二元操作符有以下几种：

-  `+`：加
-  `-`：减
-  `*`：乘
-  `/`：除
-  `%`：求余
-  `^`：乘方

算术类二元操作符可以使用在标量与标量、向量与标量，以及向量与向量之间。

**二元操作符上下文里的向量特指瞬时向量，不包括区间向量。**

- 标量与标量之间，结果很明显，跟通常的算术运算一致。
- 向量与标量之间，相当于把标量跟向量里的每一个标量进行运算，这些计算结果组成了一个新的向量。
- 向量与向量之间，会稍微麻烦一些。运算的时候首先会为左边向量里的每一个元素在右边向量里去寻找一个匹配元素（匹配规则后面会讲），然后对这两个匹配元素执行计算，这样每对匹配元素的计算结果组成了一个新的向量。如果没有找到匹配元素，则该元素丢弃。

#### 2.1.2 比较类二元操作符

比较类二元操作符有以下几种：

-  `==` (equal)
-  `!=` (not-equal)
-  `>` (greater-than)
-  `<` (less-than)
-  `>=` (greater-or-equal)
-  `<=` (less-or-equal)

比较类二元操作符同样可以使用在标量与标量、向量与标量，以及向量与向量之间。默认执行的是过滤，也就是保留值。

也可以通过在运算符后面跟 bool 修饰符来使得返回值 0 和 1，而不是过滤。

- 标量与标量之间，必须跟 bool 修饰符，因此结果只可能是 0（false） 或 1（true）。
- 向量与标量之间，相当于把向量里的每一个标量跟标量进行比较，结果为真则保留，否则丢弃。如果后面跟了 bool 修饰符，则结果分别为 1 和 0。
- 向量与向量之间，运算过程类似于算术类操作符，只不过如果比较结果为真则保留左边的值（包括度量指标和标签这些属性），否则丢弃，没找到匹配也是丢弃。如果后面跟了 bool 修饰符，则保留和丢弃时结果相应为 1 和 0。

#### 2.1.3 逻辑类二元操作符

逻辑操作符仅用于向量与向量之间。

-  `and`：交集
-  `or`：合集
-  `unless`：补集

具体运算规则如下：

-  `vector1 and vector2` 的结果由在 vector2 里有匹配（标签键值对组合相同）元素的 vector1 里的元素组成。
-  `vector1 or vector2` 的结果由所有 vector1 里的元素加上在 vector1 里没有匹配（标签键值对组合相同）元素的 vector2 里的元素组成。
-  `vector1 unless vector2` 的结果由在 vector2 里没有匹配（标签键值对组合相同）元素的 vector1 里的元素组成。

#### 2.1.4 二元操作符优先级

PromQL 的各类二元操作符运算优先级如下：

1. `^`
2. `*, /, %`
3. `+, -`
4. `==, !=, <=, <, >=, >`
5. `and, unless`
6. `or`



### 2.2 向量匹配

前面算术类和比较类操作符都需要在向量之间进行匹配。共有两种匹配类型，`one-to-one` 和 `many-to-one` / `one-to-many`。

#### 2.2.1 One-to-one 向量匹配

这种匹配模式下，两边向量里的元素如果其标签键值对组合相同则为匹配，并且只会有一个匹配元素。可以使用 `ignoring` 关键词来忽略不参与匹配的标签，或者使用 `on` 关键词来指定要参与匹配的标签。语法如下：

```
<vector expr> <bin-op> ignoring(<label list>) <vector expr>
<vector expr> <bin-op> on(<label list>) <vector expr>
```

比如对于下面的输入：

```
method_code:http_errors:rate5m{method="get", code="500"}  24
method_code:http_errors:rate5m{method="get", code="404"}  30
method_code:http_errors:rate5m{method="put", code="501"}  3
method_code:http_errors:rate5m{method="post", code="500"} 6
method_code:http_errors:rate5m{method="post", code="404"} 21

method:http_requests:rate5m{method="get"}  600
method:http_requests:rate5m{method="del"}  34
method:http_requests:rate5m{method="post"} 120
```

执行下面的查询：

```
method_code:http_errors:rate5m{code="500"} / ignoring(code) method:http_requests:rate5m
```

得到的结果为：

```
{method="get"}  0.04            //  24 / 600
{method="post"} 0.05            //   6 / 120
```

也就是每一种 method 里 code 为 500 的请求数占总数的百分比。由于 method 为 put 和 del 的没有匹配元素所以没有出现在结果里。

#### 2.2.2 Many-to-one / one-to-many 向量匹配

这种匹配模式下，某一边会有多个元素跟另一边的元素匹配。这时就需要使用 `group_left` 或 `group_right` 组修饰符来指明哪边匹配元素较多，左边多则用 `group_left`，右边多则用 `group_right`。其语法如下：

```
<vector expr> <bin-op> ignoring(<label list>) group_left(<label list>) <vector expr>
<vector expr> <bin-op> ignoring(<label list>) group_right(<label list>) <vector expr>
<vector expr> <bin-op> on(<label list>) group_left(<label list>) <vector expr>
<vector expr> <bin-op> on(<label list>) group_right(<label list>) <vector expr>
```

**组修饰符只适用于算术类和比较类操作符。**

对于前面的输入，执行下面的查询：

```
method_code:http_errors:rate5m / ignoring(code) group_left method:http_requests:rate5m
```

将得到下面的结果：

```
{method="get", code="500"}  0.04            //  24 / 600
{method="get", code="404"}  0.05            //  30 / 600
{method="post", code="500"} 0.05            //   6 / 120
{method="post", code="404"} 0.175           //  21 / 120
```

也就是每种 method 的每种 code 错误次数占每种 method 请求数的比例。这里匹配的时候 ignoring 了 code，才使得两边可以形成 Many-to-one 形式的匹配。由于左边多，所以需要使用 group_left 来指明。

Many-to-one / one-to-many 过于高级和复杂，要尽量避免使用。很多时候通过 ignoring 就可以解决问题。

#### 2.3 聚合操作符

PromQL 的聚合操作符用来将向量里的元素聚合得更少。总共有下面这些聚合操作符：

- sum：求和
- min：最小值
- max：最大值
- avg：平均值
- stddev：标准差
- stdvar：方差
- count：元素个数
- count_values：等于某值的元素个数
- bottomk：最小的 k 个元素
- topk：最大的 k 个元素
- quantile：分位数

聚合操作符语法如下：

```
<aggr-op>([parameter,] <vector expression>) [without|by (<label list>)]
```

其中 `without` 用来指定不需要保留的标签（也就是这些标签的多个值会被聚合），而 `by` 正好相反，用来指定需要保留的标签（也就是按这些标签来聚合）。

下面来看几个示例：

```
sum(http_requests_total) without (instance)
```

http_requests_total 度量指标带有 application、instance 和 group 三个标签。上面的表达式会得到每个 application 的每个 group 在所有 instance 上的请求总数。效果等同于下面的表达式：

```
sum(http_requests_total) by (application, group)
```

下面的表达式可以得到所有 application 的所有 group 的所有 instance 的请求总数。

```
sum(http_requests_total)
```

## 3. 内置函数

Prometheus 内置了一些函数来辅助计算，下面介绍一些典型的。



一些函数有默认的参数，例如：`year(v=vector(time()) instant-vector)`。v是参数值，instant-vector是参数类型。vector(time())是默认值。

### abs()

`abs(v instant-vector)`返回输入向量的所有样本的绝对值。

### absent()

`absent(v instant-vector)`，如果赋值给它的向量具有样本数据，则返回空向量；如果传递的瞬时向量参数没有样本数据，则返回不带度量指标名称且带有标签的样本值为1的结果

当监控度量指标时，如果获取到的样本数据是空的， 使用absent方法对告警是非常有用的

> absent(nonexistent{job=”myjob”}) # => key: value = {job=”myjob”}: 1
>
> absent(nonexistent{job=”myjob”, instance=~”.*”}) # => {job=”myjob”} 1
> so smart !
>
> absent(sum(nonexistent{job=”myjob”})) # => key:value {}: 0

### ceil()

`ceil(v instant-vector)` 是一个向上舍入为最接近的整数。

### changes()

`changes(v range-vector)` 输入一个范围向量， 返回这个范围向量内每个样本数据值变化的次数。

### clamp_max()

`clamp_max(v instant-vector, max scalar)`函数，输入一个瞬时向量和最大值，样本数据值若大于max，则改为max，否则不变

### clamp_min()

`clamp_min(v instant-vector)`函数，输入一个瞬时向量和最大值，样本数据值小于min，则改为min。否则不变

### count_saclar()

`count_scalar(v instant-vector)` 函数, 输入一个瞬时向量，返回key:value=”scalar”: 样本个数。而`count()`函数，输入一个瞬时向量，返回key:value=向量：样本个数，其中结果中的向量允许通过`by`条件分组。

### day_of_month()

`day_of_month(v=vector(time()) instant-vector)`函数，返回被给定UTC时间所在月的第几天。返回值范围：1~31。

### day_of_week()

`day_of_week(v=vector(time()) instant-vector)`函数，返回被给定UTC时间所在周的第几天。返回值范围：0~6. 0表示星期天。

### days_in_month()

`days_in_month(v=vector(time()) instant-vector)`函数，返回当月一共有多少天。返回值范围：28~31.

### delta()

`delta(v range-vector)`函数，计算一个范围向量v的第一个元素和最后一个元素之间的差值。返回值：key:value=度量指标：差值

下面这个表达式例子，返回过去两小时的CPU温度差：

> delta(cpu_temp_celsius{host=”zeus”}[2h])

`delta`函数返回值类型只能是gauges。

### deriv()

`deriv(v range-vector)`函数，计算一个范围向量v中各个时间序列二阶导数，使用[简单线性回归](https://en.wikipedia.org/wiki/Simple_linear_regression)

`deriv`二阶导数返回值类型只能是gauges。

### drop_common_labels()

`drop_common_labels(instant-vector)`函数，输入一个瞬时向量，返回值是key:value=度量指标：样本值，其中度量指标是去掉了具有相同标签。
例如：http_requests_total{code=”200”, host=”127.0.0.1:9090”, method=”get”} : 4, http_requests_total{code=”200”, host=”127.0.0.1:9090”, method=”post”} : 5, 返回值: http_requests_total{method=”get”} : 4, http_requests_total{code=”200”, method=”post”} : 5

### exp()

`exp(v instant-vector)`函数，输入一个瞬时向量, 返回各个样本值的e指数值，即为e^N次方。特殊情况如下所示：

> Exp(+inf) = +Inf
> Exp(NaN) = NaN

### floor()

`floor(v instant-vector)`函数，与`ceil()`函数相反。 4.3 为 4 。

### histogram_quantile()

`histogram_quatile(φ float, b instant-vector)` 函数计算b向量的φ-直方图 (0 ≤ φ ≤ 1) 。参考中文文献[<https://www.howtoing.com/how-to-query-prometheus-on-ubuntu-14-04-part-2/>]

### holt_winters()

`holt_winters(v range-vector, sf scalar, tf scalar)`函数基于范围向量v，生成事件序列数据平滑值。平滑因子`sf`越低, 对老数据越重要。趋势因子`tf`越高，越多的数据趋势应该被重视。0< sf, tf <=1。 `holt_winters`仅用于gauges

### hour()

`hour(v=vector(time()) instant-vector)`函数返回被给定UTC时间的当前第几个小时，时间范围：0~23。

### idelta()

`idelta(v range-vector)`函数，输入一个范围向量，返回key: value = 度量指标： 每最后两个样本值差值。

### increase()

`increase(v range-vector)`函数， 输入一个范围向量，返回：key:value = 度量指标：last值-first值，自动调整单调性，如：服务实例重启，则计数器重置。与`delta()`不同之处在于delta是求差值，而increase返回最后一个减第一个值,可为正为负。

下面的表达式例子，返回过去5分钟，连续两个时间序列数据样本值的http请求增加值。

> increase(http_requests_total{job=”api-server”}[5m])

`increase`的返回值类型只能是counters，主要作用是增加图表和数据的可读性，使用`rate`记录规则的使用率，以便持续跟踪数据样本值的变化。

### irate

计算的是给定时间窗口内的每秒瞬时增加速率.

`irate(v range-vector)`函数, 输入：范围向量，输出：key: value = 度量指标： (last值-last前一个值)/时间戳差值。它是基于最后两个数据点，自动调整单调性， 如：服务实例重启，则计数器重置。

下面表达式针对范围向量中的每个时间序列数据，返回两个最新数据点过去5分钟的HTTP请求速率。

> irate(http_requests_total{job=”api-server”}[5m])

`irate`只能用于绘制快速移动的计数器。因为速率的简单更改可以重置FOR子句，利用警报和缓慢移动的计数器，完全由罕见的尖峰组成的图形很难阅读。

### label_replace()

对于v中的每个时间序列，`label_replace(v instant-vector, dst_label string, replacement string, src_label string, regex string)` 将正则表达式与标签值src_label匹配。如果匹配，则返回时间序列，标签值dst_label被替换的扩展替换。$1替换为第一个匹配子组，$2替换为第二个等。如果正则表达式不匹配，则时间序列不会更改。

另一种更容易的理解是：`label_replace`函数，输入：瞬时向量，输出：key: value = 度量指标： 值（要替换的内容：首先，针对src_label标签，对该标签值进行regex正则表达式匹配。如果不能匹配的度量指标，则不发生任何改变；否则，如果匹配，则把dst_label标签的标签纸替换为replacement
下面这个例子返回一个向量值a带有`foo`标签：
`label_replace(up{job="api-server", serice="a:c"}, "foo", "$1", "service", "(.*):.*")`

### ln()

`ln(v instance-vector)`计算瞬时向量v中所有样本数据的自然对数。特殊例子：

> ln(+Inf) = +Inf
> ln(0) = -Inf
> ln(x<0) = NaN
> ln(NaN) = NaN

### log2()

`log2(v instant-vector)`函数计算瞬时向量v中所有样本数据的二进制对数。

### log10()

`log10(v instant-vector)`函数计算瞬时向量v中所有样本数据的10进制对数。相当于ln()

### minute()

`minute(v=vector(time()) instant-vector)`函数返回给定UTC时间当前小时的第多少分钟。结果范围：0~59。

### month()

`month(v=vector(time()) instant-vector)`函数返回给定UTC时间当前属于第几个月，结果范围：0~12。

### predict_linear()

`predict_linear(v range-vector, t scalar)`预测函数，输入：范围向量和从现在起t秒后，输出：不带有度量指标，只有标签列表的结果值。

```
例如：predict_linear(http_requests_total{code="200",instance="120.77.65.193:9090",job="prometheus",method="get"}[5m], 5)结果：{code="200",handler="query_range",instance="120.77.65.193:9090",job="prometheus",method="get"}  1{code="200",handler="prometheus",instance="120.77.65.193:9090",job="prometheus",method="get"}   4283.449995397104{code="200",handler="static",instance="120.77.65.193:9090",job="prometheus",method="get"}   22.99999999999999{code="200",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    130.90381188596754{code="200",handler="graph",instance="120.77.65.193:9090",job="prometheus",method="get"}    2{code="200",handler="label_values",instance="120.77.65.193:9090",job="prometheus",method="get"} 2
```

### rate()

计算的是给定时间窗口内的每秒的平均值.

`rate(v range-vector)`函数, 输入：范围向量，输出：key: value = 不带有度量指标，且只有标签列表：(last值-first值)/时间差s

```
rate(http_requests_total[5m])结果：{code="200",handler="label_values",instance="120.77.65.193:9090",job="prometheus",method="get"} 0{code="200",handler="query_range",instance="120.77.65.193:9090",job="prometheus",method="get"}  0{code="200",handler="prometheus",instance="120.77.65.193:9090",job="prometheus",method="get"}   0.2{code="200",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    0.003389830508474576{code="422",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    0{code="200",handler="static",instance="120.77.65.193:9090",job="prometheus",method="get"}   0{code="200",handler="graph",instance="120.77.65.193:9090",job="prometheus",method="get"}    0{code="400",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    0
```

`rate()`函数返回值类型只能用counters， 当用图表显示增长缓慢的样本数据时，这个函数是非常合适的。

注意：当rate函数和聚合方式联合使用时，一般先使用rate函数，再使用聚合操作, 否则，当服务实例重启后，rate无法检测到counter重置。

### resets()

`resets()`函数, 输入：一个范围向量，输出：key-value=没有度量指标，且有标签列表[在这个范围向量中每个度量指标被重置的次数]。在两个连续样本数据值下降，也可以理解为counter被重置。
示例：

```
resets(http_requests_total[5m])结果：{code="200",handler="label_values",instance="120.77.65.193:9090",job="prometheus",method="get"} 0{code="200",handler="query_range",instance="120.77.65.193:9090",job="prometheus",method="get"}  0{code="200",handler="prometheus",instance="120.77.65.193:9090",job="prometheus",method="get"}   0{code="200",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    0{code="422",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    0{code="200",handler="static",instance="120.77.65.193:9090",job="prometheus",method="get"}   0{code="200",handler="graph",instance="120.77.65.193:9090",job="prometheus",method="get"}    0{code="400",handler="query",instance="120.77.65.193:9090",job="prometheus",method="get"}    0
```

resets只能和counters一起使用。

### round()

`round(v instant-vector, to_nearest 1= scalar)`函数，与`ceil`和`floor`函数类似，输入：瞬时向量，输出：指定整数级的四舍五入值, 如果不指定，则是1以内的四舍五入。

### scalar()

`scalar(v instant-vector)`函数, 输入：瞬时向量，输出：key: value = “scalar”, 样本值[如果度量指标样本数量大于1或者等于0, 则样本值为NaN, 否则，样本值本身]

### sort()

`sort(v instant-vector)`函数，输入：瞬时向量，输出：key: value = 度量指标：样本值[升序排列]

### sort_desc()

`sort(v instant-vector`函数，输入：瞬时向量，输出：key: value = 度量指标：样本值[降序排列]

### sqrt()

`sqrt(v instant-vector)`函数，输入：瞬时向量，输出：key: value = 度量指标： 样本值的平方根

### time()

`time()`函数，返回从1970-01-01到现在的秒数，注意：它不是直接返回当前时间，而是时间戳

### vector()

`vector(s scalar)`函数，返回：key: value= {}, 传入参数值

### year()

`year(v=vector(time()) instant-vector)`, 返回年份。

### _over_time()

下面的函数列表允许传入一个范围向量，返回一个带有聚合的瞬时向量:

- `avg_over_time(range-vector)`: 范围向量内每个度量指标的平均值。
- `min_over_time(range-vector)`: 范围向量内每个度量指标的最小值。
- `max_over_time(range-vector)`: 范围向量内每个度量指标的最大值。
- `sum_over_time(range-vector)`: 范围向量内每个度量指标的求和值。
- `count_over_time(range-vector)`: 范围向量内每个度量指标的样本数据个数。
- `quantile_over_time(scalar, range-vector)`: 范围向量内每个度量指标的样本数据值分位数，φ-quantile (0 ≤ φ ≤ 1)
- `stddev_over_time(range-vector)`: 范围向量内每个度量指标的总体标准偏差。
- `stdvar_over_time(range-vector): 范围向量内每个度量指标的总体标准方差。