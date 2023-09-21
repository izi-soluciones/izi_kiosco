import 'package:flutter/material.dart';

class KioskHandIcon extends StatelessWidget {
  final double width;
  const KioskHandIcon({super.key,required this.width});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, (width*1.1785714285714286).toDouble()), //You can Replace [WIDTH] with your desired width for Custom Paint and height will be calculated automatically
      painter: RPSCustomPainter(),
    );
  }
}



//Copy this CustomPainter code to the Bottom of the File
class RPSCustomPainter extends CustomPainter {
@override
void paint(Canvas canvas, Size size) {

Path path_0 = Path();
path_0.moveTo(size.width*0.2544257,size.height*0.2508509);
path_0.cubicTo(size.width*0.2675471,size.height*0.2474448,size.width*0.2710771,size.height*0.2368842,size.width*0.2630829,size.height*0.2303818);
path_0.cubicTo(size.width*0.2490721,size.height*0.2190200,size.width*0.2345407,size.height*0.2081218,size.width*0.2198943,size.height*0.1973467);
path_0.cubicTo(size.width*0.2138750,size.height*0.1928988,size.width*0.2054036,size.height*0.1936933,size.width*0.2003343,size.height*0.1982921);
path_0.cubicTo(size.width*0.1949057,size.height*0.2032182,size.width*0.1949807,size.height*0.2102715,size.width*0.2013836,size.height*0.2152976);
path_0.cubicTo(size.width*0.2152036,size.height*0.2261642,size.width*0.2291379,size.height*0.2369085,size.width*0.2435121,size.height*0.2472570);
path_0.cubicTo(size.width*0.2469243,size.height*0.2496885,size.width*0.2522300,size.height*0.2501818,size.width*0.2544257,size.height*0.2508509);
path_0.close();
path_0.moveTo(size.width*0.2423014,size.height*0.2718248);
path_0.cubicTo(size.width*0.2407714,size.height*0.2707879,size.width*0.2377879,size.height*0.2673703,size.width*0.2340386,size.height*0.2665836);
path_0.cubicTo(size.width*0.2146450,size.height*0.2626455,size.width*0.1951029,size.height*0.2591588,size.width*0.1754929,size.height*0.2560564);
path_0.cubicTo(size.width*0.1678621,size.height*0.2548388,size.width*0.1616943,size.height*0.2591024,size.width*0.1601250,size.height*0.2652418);
path_0.cubicTo(size.width*0.1586893,size.height*0.2708873,size.width*0.1621186,size.height*0.2774218,size.width*0.1688414,size.height*0.2788000);
path_0.cubicTo(size.width*0.1888007,size.height*0.2828097,size.width*0.2088264,size.height*0.2865727,size.width*0.2290536,size.height*0.2894588);
path_0.cubicTo(size.width*0.2389650,size.height*0.2908661,size.width*0.2462364,size.height*0.2820527,size.width*0.2423014,size.height*0.2718248);
path_0.close();
path_0.moveTo(size.width*0.4465057,size.height*0.1951400);
path_0.cubicTo(size.width*0.4424507,size.height*0.1837594,size.width*0.4297486,size.height*0.1811164,size.width*0.4216964,size.height*0.1883212);
path_0.cubicTo(size.width*0.4089336,size.height*0.1997970,size.width*0.3965721,size.height*0.2116176,size.width*0.3843400,size.height*0.2234933);
path_0.cubicTo(size.width*0.3782400,size.height*0.2294727,size.width*0.3787836,size.height*0.2366242,size.width*0.3848836,size.height*0.2411412);
path_0.cubicTo(size.width*0.3907579,size.height*0.2454927,size.width*0.3990143,size.height*0.2452594,size.width*0.4050300,size.height*0.2397594);
path_0.cubicTo(size.width*0.4179086,size.height*0.2280236,size.width*0.4305614,size.height*0.2161224,size.width*0.4427636,size.height*0.2038891);
path_0.cubicTo(size.width*0.4454393,size.height*0.2011861,size.width*0.4457971,size.height*0.1967970,size.width*0.4464900,size.height*0.1950988);
path_0.lineTo(size.width*0.4465057,size.height*0.1951400);
path_0.close();
path_0.moveTo(size.width*0.3740064,size.height*0.1596818);
path_0.cubicTo(size.width*0.3700407,size.height*0.1576315,size.width*0.3658750,size.height*0.1542218,size.width*0.3610257,size.height*0.1533745);
path_0.cubicTo(size.width*0.3550129,size.height*0.1523018,size.width*0.3486314,size.height*0.1548903,size.width*0.3470843,size.height*0.1602479);
path_0.cubicTo(size.width*0.3422086,size.height*0.1773879,size.width*0.3377043,size.height*0.1946539,size.width*0.3342186,size.height*0.2120479);
path_0.cubicTo(size.width*0.3327193,size.height*0.2196279,size.width*0.3416729,size.height*0.2255455,size.width*0.3504407,size.height*0.2241206);
path_0.cubicTo(size.width*0.3577343,size.height*0.2229224,size.width*0.3609893,size.height*0.2185067,size.width*0.3623936,size.height*0.2127782);
path_0.cubicTo(size.width*0.3660186,size.height*0.1982661,size.width*0.3697086,size.height*0.1837818,size.width*0.3732043,size.height*0.1692139);
path_0.cubicTo(size.width*0.3738064,size.height*0.1667194,size.width*0.3736650,size.height*0.1641121,size.width*0.3740064,size.height*0.1596818);
path_0.close();
path_0.moveTo(size.width*0.3013171,size.height*0.1883945);
path_0.cubicTo(size.width*0.2985721,size.height*0.1812600,size.width*0.2959571,size.height*0.1740430,size.width*0.2930664,size.height*0.1669491);
path_0.cubicTo(size.width*0.2897607,size.height*0.1590570,size.width*0.2824250,size.height*0.1553842,size.width*0.2745907,size.height*0.1574170);
path_0.cubicTo(size.width*0.2664650,size.height*0.1595309,size.width*0.2630457,size.height*0.1663194,size.width*0.2661850,size.height*0.1747594);
path_0.cubicTo(size.width*0.2713700,size.height*0.1886570,size.width*0.2767500,size.height*0.2025006,size.width*0.2821786,size.height*0.2163309);
path_0.cubicTo(size.width*0.2855114,size.height*0.2248539,size.width*0.2927029,size.height*0.2284297,size.width*0.3009929,size.height*0.2260424);
path_0.cubicTo(size.width*0.3091364,size.height*0.2236958,size.width*0.3122300,size.height*0.2171800,size.width*0.3091243,size.height*0.2085479);
path_0.cubicTo(size.width*0.3066843,size.height*0.2017848,size.width*0.3039679,size.height*0.1951442,size.width*0.3013814,size.height*0.1884224);
path_0.lineTo(size.width*0.3013171,size.height*0.1883945);
path_0.close();
path_0.moveTo(size.width*0.2012550,size.height*0.3174206);
path_0.cubicTo(size.width*0.1928357,size.height*0.3197521,size.width*0.1843364,size.height*0.3220152,size.width*0.1759493,size.height*0.3244291);
path_0.cubicTo(size.width*0.1665721,size.height*0.3272091,size.width*0.1623000,size.height*0.3333212,size.width*0.1648221,size.height*0.3400158);
path_0.cubicTo(size.width*0.1673121,size.height*0.3466279,size.width*0.1752029,size.height*0.3497812,size.width*0.1845450,size.height*0.3473309);
path_0.cubicTo(size.width*0.2012029,size.height*0.3428994,size.width*0.2178457,size.height*0.3382897,size.width*0.2343771,size.height*0.3335285);
path_0.cubicTo(size.width*0.2442243,size.height*0.3307103,size.width*0.2485471,size.height*0.3243103,size.width*0.2456864,size.height*0.3174358);
path_0.cubicTo(size.width*0.2428900,size.height*0.3107261,size.width*0.2354157,size.height*0.3080958,size.width*0.2257814,size.height*0.3106273);
path_0.cubicTo(size.width*0.2175586,size.height*0.3127679,size.width*0.2094307,size.height*0.3151558,size.width*0.2012550,size.height*0.3174206);
path_0.close();
path_0.moveTo(size.width*0.4533964,size.height*0.2729576);
path_0.cubicTo(size.width*0.4618150,size.height*0.2706255,size.width*0.4703307,size.height*0.2684042,size.width*0.4787014,size.height*0.2659485);
path_0.cubicTo(size.width*0.4879814,size.height*0.2631958,size.width*0.4923207,size.height*0.2568370,size.width*0.4898950,size.height*0.2502527);
path_0.cubicTo(size.width*0.4874050,size.height*0.2436406,size.width*0.4794329,size.height*0.2405552,size.width*0.4701221,size.height*0.2430885);
path_0.cubicTo(size.width*0.4531886,size.height*0.2476418,size.width*0.4363507,size.height*0.2523055,size.width*0.4195114,size.height*0.2571061);
path_0.cubicTo(size.width*0.4103943,size.height*0.2597224,size.width*0.4065300,size.height*0.2654933,size.width*0.4088407,size.height*0.2722006);
path_0.cubicTo(size.width*0.4112471,size.height*0.2791552,size.width*0.4187014,size.height*0.2822933,size.width*0.4281400,size.height*0.2799527);
path_0.cubicTo(size.width*0.4366379,size.height*0.2778273,size.width*0.4450421,size.height*0.2753170,size.width*0.4534607,size.height*0.2729855);
path_0.lineTo(size.width*0.4533964,size.height*0.2729576);
path_0.close();

Paint paint0Fill = Paint()..style=PaintingStyle.fill;
paint0Fill.color = Colors.white.withOpacity(1.0);
canvas.drawPath(path_0,paint0Fill);

Path path_1 = Path();
path_1.moveTo(size.width*0.4815700,size.height*0.8621152);
path_1.cubicTo(size.width*0.4728214,size.height*0.8610727,size.width*0.4680643,size.height*0.8566848,size.width*0.4657893,size.height*0.8495091);
path_1.cubicTo(size.width*0.4571314,size.height*0.8221091,size.width*0.4406093,size.height*0.7986182,size.width*0.4179979,size.height*0.7776364);
path_1.cubicTo(size.width*0.3820800,size.height*0.7443212,size.width*0.3501150,size.height*0.7084061,size.width*0.3272050,size.height*0.6674727);
path_1.cubicTo(size.width*0.3160293,size.height*0.6475212,size.width*0.3062021,size.height*0.6268788,size.width*0.2973479,size.height*0.6061030);
path_1.cubicTo(size.width*0.2867279,size.height*0.5812976,size.width*0.2776979,size.height*0.5560067,size.width*0.2681807,size.height*0.5308503);
path_1.cubicTo(size.width*0.2546986,size.height*0.4952467,size.width*0.2741150,size.height*0.4628521,size.width*0.3158064,size.height*0.4509855);
path_1.cubicTo(size.width*0.3189207,size.height*0.4501230,size.width*0.3220350,size.height*0.4492606,size.width*0.3260743,size.height*0.4481418);
path_1.cubicTo(size.width*0.3248364,size.height*0.4449248,size.width*0.3238214,size.height*0.4422855,size.width*0.3228214,size.height*0.4396873);
path_1.cubicTo(size.width*0.3066057,size.height*0.3975388,size.width*0.2902929,size.height*0.3554170,size.width*0.2741750,size.height*0.3132418);
path_1.cubicTo(size.width*0.2651807,size.height*0.2895836,size.width*0.2732443,size.height*0.2684115,size.width*0.2958457,size.height*0.2552145);
path_1.cubicTo(size.width*0.3245936,size.height*0.2383988,size.width*0.3666514,size.height*0.2481988,size.width*0.3788350,size.height*0.2759479);
path_1.cubicTo(size.width*0.3922271,size.height*0.3064200,size.width*0.4033643,size.height*0.3376079,size.width*0.4154586,size.height*0.3684848);
path_1.cubicTo(size.width*0.4165693,size.height*0.3713715,size.width*0.4176643,size.height*0.3742170,size.width*0.4190129,size.height*0.3777224);
path_1.cubicTo(size.width*0.4498707,size.height*0.3560327,size.width*0.4789671,size.height*0.3569188,size.width*0.5071886,size.height*0.3808642);
path_1.cubicTo(size.width*0.5192421,size.height*0.3690836,size.width*0.5342486,size.height*0.3625994,size.width*0.5524886,size.height*0.3628412);
path_1.cubicTo(size.width*0.5707779,size.height*0.3630697,size.width*0.5854364,size.height*0.3700988,size.width*0.5970157,size.height*0.3818600);
path_1.cubicTo(size.width*0.6216943,size.height*0.3575467,size.width*0.6549343,size.height*0.3605242,size.width*0.6740436,size.height*0.3718430);
path_1.cubicTo(size.width*0.6847107,size.height*0.3781527,size.width*0.6920750,size.height*0.3865182,size.width*0.6959764,size.height*0.3969376);
path_1.cubicTo(size.width*0.7114043,size.height*0.4383000,size.width*0.7281143,size.height*0.4793533,size.width*0.7415643,size.height*0.5211727);
path_1.cubicTo(size.width*0.7565786,size.height*0.5678982,size.width*0.7589571,size.height*0.6159333,size.width*0.7542643,size.height*0.6641939);
path_1.cubicTo(size.width*0.7536143,size.height*0.6707636,size.width*0.7533000,size.height*0.6773758,size.width*0.7522643,size.height*0.6839152);
path_1.cubicTo(size.width*0.7478143,size.height*0.7125273,size.width*0.7511929,size.height*0.7403394,size.width*0.7635429,size.height*0.7672667);
path_1.cubicTo(size.width*0.7666643,size.height*0.7741152,size.width*0.7660714,size.height*0.7801212,size.width*0.7593786,size.height*0.7852606);
path_1.lineTo(size.width*0.4816021,size.height*0.8622000);
path_1.lineTo(size.width*0.4815700,size.height*0.8621152);
path_1.close();
path_1.moveTo(size.width*0.3351179,size.height*0.4716491);
path_1.cubicTo(size.width*0.2997579,size.height*0.4770164,size.width*0.2850793,size.height*0.4975109,size.width*0.2958207,size.height*0.5254309);
path_1.cubicTo(size.width*0.3046107,size.height*0.5482788,size.width*0.3135143,size.height*0.5711406,size.width*0.3222071,size.height*0.5940152);
path_1.cubicTo(size.width*0.3423986,size.height*0.6473394,size.width*0.3732793,size.height*0.6956909,size.width*0.4158079,size.height*0.7386303);
path_1.cubicTo(size.width*0.4323821,size.height*0.7554000,size.width*0.4498507,size.height*0.7716909,size.width*0.4645386,size.height*0.7895697);
path_1.cubicTo(size.width*0.4754900,size.height*0.8029212,size.width*0.4826207,size.height*0.8185152,size.width*0.4917136,size.height*0.8336121);
path_1.lineTo(size.width*0.7321643,size.height*0.7670182);
path_1.cubicTo(size.width*0.7290214,size.height*0.7525515,size.width*0.7240000,size.height*0.7385152,size.width*0.7234143,size.height*0.7243939);
path_1.cubicTo(size.width*0.7225643,size.height*0.7042788,size.width*0.7242286,size.height*0.6839636,size.width*0.7261643,size.height*0.6638061);
path_1.cubicTo(size.width*0.7316643,size.height*0.6060139,size.width*0.7250429,size.height*0.5494788,size.width*0.7038800,size.height*0.4943261);
path_1.cubicTo(size.width*0.6925836,size.height*0.4649618,size.width*0.6813350,size.height*0.4355848,size.width*0.6699893,size.height*0.4062345);
path_1.cubicTo(size.width*0.6641979,size.height*0.3911818,size.width*0.6491521,size.height*0.3839855,size.width*0.6333850,size.height*0.3883527);
path_1.cubicTo(size.width*0.6181529,size.height*0.3925715,size.width*0.6104664,size.height*0.4068855,size.width*0.6159229,size.height*0.4213467);
path_1.cubicTo(size.width*0.6222986,size.height*0.4382000,size.width*0.6288536,size.height*0.4549582,size.width*0.6352786,size.height*0.4717982);
path_1.cubicTo(size.width*0.6361357,size.height*0.4740248,size.width*0.6370243,size.height*0.4763345,size.width*0.6372164,size.height*0.4786545);
path_1.cubicTo(size.width*0.6378807,size.height*0.4848594,size.width*0.6336000,size.height*0.4899697,size.width*0.6268550,size.height*0.4914727);
path_1.cubicTo(size.width*0.6201093,size.height*0.4929758,size.width*0.6135107,size.height*0.4902400,size.width*0.6104629,size.height*0.4845582);
path_1.cubicTo(size.width*0.6094093,size.height*0.4826594,size.width*0.6087136,size.height*0.4805709,size.width*0.6079357,size.height*0.4785497);
path_1.cubicTo(size.width*0.5987014,size.height*0.4545473,size.width*0.5897750,size.height*0.4305055,size.width*0.5800057,size.height*0.4066515);
path_1.cubicTo(size.width*0.5777179,size.height*0.4011242,size.width*0.5735200,size.height*0.3955327,size.width*0.5684193,size.height*0.3916515);
path_1.cubicTo(size.width*0.5595207,size.height*0.3848982,size.width*0.5455650,size.height*0.3852952,size.width*0.5358243,size.height*0.3910503);
path_1.cubicTo(size.width*0.5253357,size.height*0.3972412,size.width*0.5208407,size.height*0.4071115,size.width*0.5248207,size.height*0.4177376);
path_1.cubicTo(size.width*0.5341429,size.height*0.4429479,size.width*0.5440493,size.height*0.4679964,size.width*0.5535500,size.height*0.4931115);
path_1.cubicTo(size.width*0.5547400,size.height*0.4962042,size.width*0.5557986,size.height*0.4995164,size.width*0.5558543,size.height*0.5027412);
path_1.cubicTo(size.width*0.5559407,size.height*0.5082848,size.width*0.5523664,size.height*0.5121497,size.width*0.5461379,size.height*0.5137376);
path_1.cubicTo(size.width*0.5395207,size.height*0.5154339,size.width*0.5339500,size.height*0.5136909,size.width*0.5302986,size.height*0.5086782);
path_1.cubicTo(size.width*0.5285850,size.height*0.5063236,size.width*0.5276029,size.height*0.5034921,size.width*0.5265721,size.height*0.5008115);
path_1.cubicTo(size.width*0.5146721,size.height*0.4698806,size.width*0.5027721,size.height*0.4389497,size.width*0.4908236,size.height*0.4080321);
path_1.cubicTo(size.width*0.4894593,size.height*0.4044855,size.width*0.4878036,size.height*0.4008824,size.width*0.4855950,size.height*0.3976612);
path_1.cubicTo(size.width*0.4795136,size.height*0.3887121,size.width*0.4663871,size.height*0.3844073,size.width*0.4546307,size.height*0.3871612);
path_1.cubicTo(size.width*0.4371829,size.height*0.3912182,size.width*0.4295693,size.height*0.4044618,size.width*0.4357550,size.height*0.4208206);
path_1.cubicTo(size.width*0.4476836,size.height*0.4522455,size.width*0.4599043,size.height*0.4835897,size.width*0.4718807,size.height*0.5150012);
path_1.cubicTo(size.width*0.4730871,size.height*0.5181358,size.width*0.4743243,size.height*0.5213521,size.width*0.4745907,size.height*0.5245642);
path_1.cubicTo(size.width*0.4750500,size.height*0.5300958,size.width*0.4717000,size.height*0.5341267,size.width*0.4655993,size.height*0.5360448);
path_1.cubicTo(size.width*0.4591093,size.height*0.5380709,size.width*0.4532929,size.height*0.5366697,size.width*0.4495107,size.height*0.5317388);
path_1.cubicTo(size.width*0.4472671,size.height*0.5288467,size.width*0.4459343,size.height*0.5253824,size.width*0.4446493,size.height*0.5220418);
path_1.cubicTo(size.width*0.4154543,size.height*0.4462952,size.width*0.3863557,size.height*0.3705212,size.width*0.3571450,size.height*0.2947333);
path_1.cubicTo(size.width*0.3559386,size.height*0.2915994,size.width*0.3547329,size.height*0.2884648,size.width*0.3531864,size.height*0.2854248);
path_1.cubicTo(size.width*0.3475093,size.height*0.2744473,size.width*0.3340364,size.height*0.2689606,size.width*0.3201743,size.height*0.2718418);
path_1.cubicTo(size.width*0.3069121,size.height*0.2746024,size.width*0.2977307,size.height*0.2855879,size.width*0.2993221,size.height*0.2974230);
path_1.cubicTo(size.width*0.2998579,size.height*0.3013364,size.width*0.3012036,size.height*0.3052533,size.width*0.3026636,size.height*0.3090479);
path_1.cubicTo(size.width*0.3392179,size.height*0.4043418,size.width*0.3758693,size.height*0.4996091,size.width*0.4124721,size.height*0.5948897);
path_1.cubicTo(size.width*0.4135829,size.height*0.5977764,size.width*0.4149357,size.height*0.6007333,size.width*0.4152843,size.height*0.6037400);
path_1.cubicTo(size.width*0.4159836,size.height*0.6096182,size.width*0.4125829,size.height*0.6139333,size.width*0.4062386,size.height*0.6159212);
path_1.cubicTo(size.width*0.4002679,size.height*0.6177576,size.width*0.3944821,size.height*0.6165758,size.width*0.3906986,size.height*0.6119212);
path_1.cubicTo(size.width*0.3885500,size.height*0.6092727,size.width*0.3870536,size.height*0.6060848,size.width*0.3858636,size.height*0.6029897);
path_1.cubicTo(size.width*0.3699786,size.height*0.5619818,size.width*0.3542079,size.height*0.5209879,size.width*0.3383721,size.height*0.4799661);
path_1.cubicTo(size.width*0.3373407,size.height*0.4772855,size.width*0.3363093,size.height*0.4746048,size.width*0.3351350,size.height*0.4715533);
path_1.lineTo(size.width*0.3351179,size.height*0.4716491);
path_1.close();

Paint paint1Fill = Paint()..style=PaintingStyle.fill;
paint1Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_1,paint1Fill);

Path path_2 = Path();
path_2.moveTo(size.width*0.2544257,size.height*0.2508509);
path_2.cubicTo(size.width*0.2522300,size.height*0.2501818,size.width*0.2468757,size.height*0.2497024,size.width*0.2435121,size.height*0.2472570);
path_2.cubicTo(size.width*0.2291536,size.height*0.2369497,size.width*0.2151707,size.height*0.2262194,size.width*0.2013836,size.height*0.2152976);
path_2.cubicTo(size.width*0.1949807,size.height*0.2102715,size.width*0.1949543,size.height*0.2032048,size.width*0.2003343,size.height*0.1982921);
path_2.cubicTo(size.width*0.2054036,size.height*0.1936933,size.width*0.2138757,size.height*0.1928988,size.width*0.2198943,size.height*0.1973467);
path_2.cubicTo(size.width*0.2345407,size.height*0.2081218,size.width*0.2490721,size.height*0.2190200,size.width*0.2630829,size.height*0.2303818);
path_2.cubicTo(size.width*0.2710771,size.height*0.2368842,size.width*0.2675314,size.height*0.2474036,size.width*0.2544257,size.height*0.2508509);
path_2.close();

Paint paint2Fill = Paint()..style=PaintingStyle.fill;
paint2Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_2,paint2Fill);

Path path_3 = Path();
path_3.moveTo(size.width*0.2423014,size.height*0.2718248);
path_3.cubicTo(size.width*0.2462364,size.height*0.2820527,size.width*0.2389807,size.height*0.2909073,size.width*0.2290536,size.height*0.2894588);
path_3.cubicTo(size.width*0.2088757,size.height*0.2865594,size.width*0.1887850,size.height*0.2827685,size.width*0.1688421,size.height*0.2788000);
path_3.cubicTo(size.width*0.1620700,size.height*0.2774352,size.width*0.1586893,size.height*0.2708873,size.width*0.1601257,size.height*0.2652418);
path_3.cubicTo(size.width*0.1616457,size.height*0.2591158,size.width*0.1678621,size.height*0.2548388,size.width*0.1754929,size.height*0.2560564);
path_3.cubicTo(size.width*0.1951029,size.height*0.2591588,size.width*0.2146450,size.height*0.2626455,size.width*0.2340386,size.height*0.2665836);
path_3.cubicTo(size.width*0.2377721,size.height*0.2673291,size.width*0.2407721,size.height*0.2707879,size.width*0.2423014,size.height*0.2718248);
path_3.close();

Paint paint3Fill = Paint()..style=PaintingStyle.fill;
paint3Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_3,paint3Fill);

Path path_4 = Path();
path_4.moveTo(size.width*0.4465057,size.height*0.1951406);
path_4.cubicTo(size.width*0.4458129,size.height*0.1968382,size.width*0.4454550,size.height*0.2012273,size.width*0.4427793,size.height*0.2039303);
path_4.cubicTo(size.width*0.4305771,size.height*0.2161636,size.width*0.4179243,size.height*0.2280648,size.width*0.4050457,size.height*0.2398006);
path_4.cubicTo(size.width*0.3990300,size.height*0.2453006,size.width*0.3907736,size.height*0.2455339,size.width*0.3848993,size.height*0.2411824);
path_4.cubicTo(size.width*0.3787993,size.height*0.2366655,size.width*0.3782400,size.height*0.2294727,size.width*0.3843564,size.height*0.2235352);
path_4.cubicTo(size.width*0.3965721,size.height*0.2116176,size.width*0.4089336,size.height*0.1997970,size.width*0.4217121,size.height*0.1883624);
path_4.cubicTo(size.width*0.4297643,size.height*0.1811576,size.width*0.4424021,size.height*0.1837727,size.width*0.4465221,size.height*0.1951818);
path_4.lineTo(size.width*0.4465057,size.height*0.1951406);
path_4.close();

Paint paint4Fill = Paint()..style=PaintingStyle.fill;
paint4Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_4,paint4Fill);

Path path_5 = Path();
path_5.moveTo(size.width*0.3740064,size.height*0.1596818);
path_5.cubicTo(size.width*0.3736650,size.height*0.1641121,size.width*0.3738064,size.height*0.1667194,size.width*0.3732043,size.height*0.1692139);
path_5.cubicTo(size.width*0.3696929,size.height*0.1837400,size.width*0.3660186,size.height*0.1982661,size.width*0.3623936,size.height*0.2127782);
path_5.cubicTo(size.width*0.3609736,size.height*0.2184655,size.width*0.3576700,size.height*0.2228945,size.width*0.3504407,size.height*0.2241206);
path_5.cubicTo(size.width*0.3417379,size.height*0.2255727,size.width*0.3327350,size.height*0.2196697,size.width*0.3342186,size.height*0.2120479);
path_5.cubicTo(size.width*0.3377043,size.height*0.1946539,size.width*0.3422243,size.height*0.1774291,size.width*0.3470843,size.height*0.1602479);
path_5.cubicTo(size.width*0.3485821,size.height*0.1549042,size.width*0.3550129,size.height*0.1523018,size.width*0.3610257,size.height*0.1533745);
path_5.cubicTo(size.width*0.3658264,size.height*0.1542352,size.width*0.3700564,size.height*0.1576727,size.width*0.3740064,size.height*0.1596818);
path_5.close();

Paint paint5Fill = Paint()..style=PaintingStyle.fill;
paint5Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_5,paint5Fill);

Path path_6 = Path();
path_6.moveTo(size.width*0.3013657,size.height*0.1883812);
path_6.cubicTo(size.width*0.3039521,size.height*0.1951030,size.width*0.3066200,size.height*0.2017576,size.width*0.3091086,size.height*0.2085067);
path_6.cubicTo(size.width*0.3122629,size.height*0.2171255,size.width*0.3091207,size.height*0.2236545,size.width*0.3009771,size.height*0.2260012);
path_6.cubicTo(size.width*0.2926871,size.height*0.2283885,size.width*0.2855600,size.height*0.2248406,size.width*0.2821629,size.height*0.2162897);
path_6.cubicTo(size.width*0.2767343,size.height*0.2024594,size.width*0.2713543,size.height*0.1886158,size.width*0.2661693,size.height*0.1747182);
path_6.cubicTo(size.width*0.2630300,size.height*0.1662782,size.width*0.2664493,size.height*0.1594897,size.width*0.2745750,size.height*0.1573758);
path_6.cubicTo(size.width*0.2824086,size.height*0.1553430,size.width*0.2897450,size.height*0.1590158,size.width*0.2930507,size.height*0.1669079);
path_6.cubicTo(size.width*0.2959900,size.height*0.1739885,size.width*0.2985564,size.height*0.1812182,size.width*0.3013014,size.height*0.1883533);
path_6.lineTo(size.width*0.3013657,size.height*0.1883812);
path_6.close();

Paint paint6Fill = Paint()..style=PaintingStyle.fill;
paint6Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_6,paint6Fill);

Path path_7 = Path();
path_7.moveTo(size.width*0.2013193,size.height*0.3174479);
path_7.cubicTo(size.width*0.2094950,size.height*0.3151836,size.width*0.2176386,size.height*0.3128370,size.width*0.2258457,size.height*0.3106552);
path_7.cubicTo(size.width*0.2354807,size.height*0.3081236,size.width*0.2429543,size.height*0.3107539,size.width*0.2457514,size.height*0.3174636);
path_7.cubicTo(size.width*0.2486114,size.height*0.3243382,size.width*0.2442886,size.height*0.3307376,size.width*0.2344414,size.height*0.3335564);
path_7.cubicTo(size.width*0.2178943,size.height*0.3382764,size.width*0.2012671,size.height*0.3429273,size.width*0.1846093,size.height*0.3473588);
path_7.cubicTo(size.width*0.1752829,size.height*0.3498503,size.width*0.1673436,size.height*0.3467103,size.width*0.1648864,size.height*0.3400430);
path_7.cubicTo(size.width*0.1623650,size.height*0.3333485,size.width*0.1666371,size.height*0.3272370,size.width*0.1760143,size.height*0.3244570);
path_7.cubicTo(size.width*0.1843857,size.height*0.3220012,size.width*0.1929007,size.height*0.3197800,size.width*0.2013193,size.height*0.3174479);
path_7.close();

Paint paint7Fill = Paint()..style=PaintingStyle.fill;
paint7Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_7,paint7Fill);

Path path_8 = Path();
path_8.moveTo(size.width*0.4534450,size.height*0.2729442);
path_8.cubicTo(size.width*0.4450264,size.height*0.2752758,size.width*0.4366221,size.height*0.2777861,size.width*0.4281243,size.height*0.2799115);
path_8.cubicTo(size.width*0.4186857,size.height*0.2822521,size.width*0.4112314,size.height*0.2791139,size.width*0.4088250,size.height*0.2721594);
path_8.cubicTo(size.width*0.4065143,size.height*0.2654521,size.width*0.4103300,size.height*0.2596945,size.width*0.4194957,size.height*0.2570648);
path_8.cubicTo(size.width*0.4363186,size.height*0.2522230,size.width*0.4531721,size.height*0.2476006,size.width*0.4701064,size.height*0.2430473);
path_8.cubicTo(size.width*0.4794329,size.height*0.2405552,size.width*0.4874379,size.height*0.2435861,size.width*0.4898793,size.height*0.2502115);
path_8.cubicTo(size.width*0.4923536,size.height*0.2567824,size.width*0.4879657,size.height*0.2631545,size.width*0.4786857,size.height*0.2659073);
path_8.cubicTo(size.width*0.4703307,size.height*0.2684042,size.width*0.4617993,size.height*0.2705842,size.width*0.4533807,size.height*0.2729164);
path_8.lineTo(size.width*0.4534450,size.height*0.2729442);
path_8.close();

Paint paint8Fill = Paint()..style=PaintingStyle.fill;
paint8Fill.color = const Color(0xff696979).withOpacity(1.0);
canvas.drawPath(path_8,paint8Fill);

}

@override
bool shouldRepaint(covariant CustomPainter oldDelegate) {
return true;
}
}