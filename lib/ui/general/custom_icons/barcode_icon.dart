import 'package:flutter/material.dart';

class BarcodeIcon extends StatelessWidget {
  final double width;
  const BarcodeIcon({super.key,required this.width});

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
path_0.moveTo(size.width*0.8051144,size.height*0.7302830);
path_0.cubicTo(size.width*0.8051144,size.height*0.7302830,size.width*0.8050796,size.height*0.7302830,size.width*0.8050498,size.height*0.7302830);
path_0.cubicTo(size.width*0.8050498,size.height*0.7379245,size.width*0.8050995,size.height*0.7455660,size.width*0.8050498,size.height*0.7532075);
path_0.cubicTo(size.width*0.8048706,size.height*0.7778365,size.width*0.7934229,size.height*0.7923145,size.width*0.7739154,size.height*0.7924969);
path_0.cubicTo(size.width*0.7620299,size.height*0.7926226,size.width*0.7501642,size.height*0.7924591,size.width*0.7382786,size.height*0.7925597);
path_0.cubicTo(size.width*0.7280547,size.height*0.7926415,size.width*0.7220199,size.height*0.7991321,size.width*0.7221194,size.height*0.8097107);
path_0.cubicTo(size.width*0.7222189,size.height*0.8199182,size.width*0.7282189,size.height*0.8265535,size.width*0.7379403,size.height*0.8266981);
path_0.cubicTo(size.width*0.7506816,size.height*0.8268616,size.width*0.7634279,size.height*0.8270692,size.width*0.7761592,size.height*0.8266792);
path_0.cubicTo(size.width*0.8028557,size.height*0.8258365,size.width*0.8247015,size.height*0.8065912,size.width*0.8294975,size.height*0.7743836);
path_0.cubicTo(size.width*0.8329950,size.height*0.7509057,size.width*0.8316766,size.height*0.7261384,size.width*0.8314030,size.height*0.7019811);
path_0.cubicTo(size.width*0.8313035,size.height*0.6924277,size.width*0.8245075,size.height*0.6870881,size.width*0.8173234,size.height*0.6878302);
path_0.cubicTo(size.width*0.8103483,size.height*0.6885472,size.width*0.8054527,size.height*0.6951447,size.width*0.8051642,size.height*0.7049371);
path_0.cubicTo(size.width*0.8049204,size.height*0.7133836,size.width*0.8051144,size.height*0.7218616,size.width*0.8051144,size.height*0.7303082);
path_0.lineTo(size.width*0.8051144,size.height*0.7302830);
path_0.close();
path_0.moveTo(size.width*0.8051144,size.height*0.2925692);
path_0.cubicTo(size.width*0.8051144,size.height*0.2991208,size.width*0.8051144,size.height*0.3056730,size.width*0.8051144,size.height*0.3122459);
path_0.cubicTo(size.width*0.8051144,size.height*0.3138887,size.width*0.8050995,size.height*0.3155321,size.width*0.8051144,size.height*0.3171547);
path_0.cubicTo(size.width*0.8053433,size.height*0.3290673,size.width*0.8102687,size.height*0.3363182,size.width*0.8182338,size.height*0.3365031);
path_0.cubicTo(size.width*0.8261990,size.height*0.3366874,size.width*0.8318557,size.height*0.3294579,size.width*0.8320348,size.height*0.3178528);
path_0.cubicTo(size.width*0.8322786,size.height*0.3009283,size.width*0.8325373,size.height*0.2839629,size.width*0.8319851,size.height*0.2670591);
path_0.cubicTo(size.width*0.8307512,size.height*0.2296358,size.width*0.8118607,size.height*0.2028937,size.width*0.7826617,size.height*0.1988478);
path_0.cubicTo(size.width*0.7677065,size.height*0.1967730,size.width*0.7524577,size.height*0.1976767,size.width*0.7373383,size.height*0.1976975);
path_0.cubicTo(size.width*0.7280697,size.height*0.1976975,size.width*0.7222338,size.height*0.2046396,size.width*0.7221542,size.height*0.2146220);
path_0.cubicTo(size.width*0.7220697,size.height*0.2249736,size.width*0.7279552,size.height*0.2315050,size.width*0.7377612,size.height*0.2316283);
path_0.cubicTo(size.width*0.7494328,size.height*0.2317516,size.width*0.7611045,size.height*0.2316283,size.width*0.7727761,size.height*0.2316899);
path_0.cubicTo(size.width*0.7938955,size.height*0.2317931,size.width*0.8050348,size.height*0.2460264,size.width*0.8050796,size.height*0.2729126);
path_0.cubicTo(size.width*0.8050796,size.height*0.2794648,size.width*0.8050796,size.height*0.2860170,size.width*0.8050796,size.height*0.2925893);
path_0.lineTo(size.width*0.8051144,size.height*0.2925692);
path_0.close();
path_0.moveTo(size.width*0.6102537,size.height*0.6875409);
path_0.cubicTo(size.width*0.6102537,size.height*0.6875409,size.width*0.6103035,size.height*0.6875409,size.width*0.6103333,size.height*0.6875409);
path_0.cubicTo(size.width*0.6103333,size.height*0.6818113,size.width*0.6103333,size.height*0.6761006,size.width*0.6103333,size.height*0.6703711);
path_0.cubicTo(size.width*0.6103333,size.height*0.6698365,size.width*0.6103035,size.height*0.6692830,size.width*0.6102537,size.height*0.6687484);
path_0.cubicTo(size.width*0.6095721,size.height*0.6598994,size.width*0.6050199,size.height*0.6538365,size.width*0.5984677,size.height*0.6531006);
path_0.cubicTo(size.width*0.5911692,size.height*0.6522767,size.width*0.5850398,size.height*0.6566918,size.width*0.5844030,size.height*0.6658931);
path_0.cubicTo(size.width*0.5834428,size.height*0.6798805,size.width*0.5835274,size.height*0.6941132,size.width*0.5843532,size.height*0.7081258);
path_0.cubicTo(size.width*0.5848607,size.height*0.7165660,size.width*0.5916070,size.height*0.7220692,size.width*0.5977363,size.height*0.7214717);
path_0.cubicTo(size.width*0.6044826,size.height*0.7208176,size.width*0.6097164,size.height*0.7143899,size.width*0.6101891,size.height*0.7054969);
path_0.cubicTo(size.width*0.6105124,size.height*0.6995346,size.width*0.6102537,size.height*0.6935220,size.width*0.6102537,size.height*0.6875220);
path_0.lineTo(size.width*0.6102537,size.height*0.6875409);
path_0.close();
path_0.moveTo(size.width*0.6933582,size.height*0.6873145);
path_0.cubicTo(size.width*0.6933582,size.height*0.6873145,size.width*0.6933582,size.height*0.6873145,size.width*0.6933433,size.height*0.6873145);
path_0.cubicTo(size.width*0.6933433,size.height*0.6810503,size.width*0.6936219,size.height*0.6747484,size.width*0.6932786,size.height*0.6685031);
path_0.cubicTo(size.width*0.6928060,size.height*0.6596918,size.width*0.6879652,size.height*0.6537170,size.width*0.6813632,size.height*0.6530377);
path_0.cubicTo(size.width*0.6741592,size.height*0.6523145,size.width*0.6680149,size.height*0.6568994,size.width*0.6673831,size.height*0.6661006);
path_0.cubicTo(size.width*0.6664378,size.height*0.6798428,size.width*0.6664527,size.height*0.6938302,size.width*0.6672687,size.height*0.7075912);
path_0.cubicTo(size.width*0.6677861,size.height*0.7165031,size.width*0.6746169,size.height*0.7222327,size.width*0.6809900,size.height*0.7214528);
path_0.cubicTo(size.width*0.6878010,size.height*0.7206289,size.width*0.6928408,size.height*0.7142642,size.width*0.6932935,size.height*0.7052704);
path_0.cubicTo(size.width*0.6936070,size.height*0.6992893,size.width*0.6933582,size.height*0.6932704,size.width*0.6933582,size.height*0.6872767);
path_0.lineTo(size.width*0.6933582,size.height*0.6873145);
path_0.close();
path_0.moveTo(size.width*0.3899498,size.height*0.6865535);
path_0.cubicTo(size.width*0.3899498,size.height*0.6865535,size.width*0.3899826,size.height*0.6865535,size.width*0.3899985,size.height*0.6865535);
path_0.cubicTo(size.width*0.3899985,size.height*0.6931069,size.width*0.3896736,size.height*0.6996792,size.width*0.3900801,size.height*0.7061950);
path_0.cubicTo(size.width*0.3906000,size.height*0.7146164,size.width*0.3959164,size.height*0.7207987,size.width*0.4024353,size.height*0.7214340);
path_0.cubicTo(size.width*0.4083368,size.height*0.7220063,size.width*0.4151000,size.height*0.7167673,size.width*0.4155876,size.height*0.7087610);
path_0.cubicTo(size.width*0.4164657,size.height*0.6944654,size.width*0.4165468,size.height*0.6799434,size.width*0.4156204,size.height*0.6656667);
path_0.cubicTo(size.width*0.4150512,size.height*0.6567925,size.width*0.4090522,size.height*0.6525220,size.width*0.4019801,size.height*0.6531572);
path_0.cubicTo(size.width*0.3953960,size.height*0.6537358,size.width*0.3905025,size.height*0.6597547,size.width*0.3900149,size.height*0.6685409);
path_0.cubicTo(size.width*0.3896896,size.height*0.6745220,size.width*0.3899498,size.height*0.6805409,size.width*0.3899498,size.height*0.6865535);
path_0.close();
path_0.moveTo(size.width*0.3609955,size.height*0.6875660);
path_0.cubicTo(size.width*0.3609955,size.height*0.6815660,size.width*0.3611905,size.height*0.6755472,size.width*0.3609468,size.height*0.6695723);
path_0.cubicTo(size.width*0.3605731,size.height*0.6601824,size.width*0.3558418,size.height*0.6538805,size.width*0.3490627,size.height*0.6532201);
path_0.cubicTo(size.width*0.3417308,size.height*0.6525220,size.width*0.3357965,size.height*0.6569623,size.width*0.3351463,size.height*0.6663270);
path_0.cubicTo(size.width*0.3342035,size.height*0.6800692,size.width*0.3342846,size.height*0.6940503,size.width*0.3350975,size.height*0.7078176);
path_0.cubicTo(size.width*0.3356015,size.height*0.7163585,size.width*0.3422020,size.height*0.7219434,size.width*0.3483149,size.height*0.7214528);
path_0.cubicTo(size.width*0.3552891,size.height*0.7208994,size.width*0.3605080,size.height*0.7141635,size.width*0.3609144,size.height*0.7047547);
path_0.cubicTo(size.width*0.3611582,size.height*0.6990440,size.width*0.3609632,size.height*0.6933145,size.width*0.3609632,size.height*0.6875849);
path_0.lineTo(size.width*0.3609955,size.height*0.6875660);
path_0.close();
path_0.moveTo(size.width*0.4715294,size.height*0.6868868);
path_0.cubicTo(size.width*0.4715294,size.height*0.6868868,size.width*0.4714965,size.height*0.6868868,size.width*0.4714806,size.height*0.6868868);
path_0.cubicTo(size.width*0.4714806,size.height*0.6803333,size.width*0.4718871,size.height*0.6737421,size.width*0.4713831,size.height*0.6672704);
path_0.cubicTo(size.width*0.4706841,size.height*0.6584780,size.width*0.4655303,size.height*0.6531384,size.width*0.4586697,size.height*0.6530566);
path_0.cubicTo(size.width*0.4517930,size.height*0.6529748,size.width*0.4461353,size.height*0.6582516,size.width*0.4457612,size.height*0.6668994);
path_0.cubicTo(size.width*0.4451925,size.height*0.6802327,size.width*0.4452085,size.height*0.6936415,size.width*0.4457124,size.height*0.7069497);
path_0.cubicTo(size.width*0.4460214,size.height*0.7152704,size.width*0.4520368,size.height*0.7213899,size.width*0.4583935,size.height*0.7214969);
path_0.cubicTo(size.width*0.4649289,size.height*0.7216164,size.width*0.4708139,size.height*0.7152704,size.width*0.4714478,size.height*0.7064780);
path_0.cubicTo(size.width*0.4719194,size.height*0.6999874,size.width*0.4715453,size.height*0.6933962,size.width*0.4715453,size.height*0.6868428);
path_0.lineTo(size.width*0.4715294,size.height*0.6868868);
path_0.close();

Paint paint0Fill = Paint()..style=PaintingStyle.fill;
paint0Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_0,paint0Fill);

Path path_1 = Path();
path_1.moveTo(size.width*0.7490249,size.height*0.5117044);
path_1.cubicTo(size.width*0.7490249,size.height*0.5157094,size.width*0.7490249,size.height*0.5188931,size.width*0.7490249,size.height*0.5220969);
path_1.cubicTo(size.width*0.7490249,size.height*0.5805937,size.width*0.7490597,size.height*0.6390692,size.width*0.7489950,size.height*0.6975660);
path_1.cubicTo(size.width*0.7489950,size.height*0.7016101,size.width*0.7487512,size.height*0.7057987,size.width*0.7479055,size.height*0.7096855);
path_1.cubicTo(size.width*0.7462935,size.height*0.7171006,size.width*0.7404080,size.height*0.7220692,size.width*0.7346866,size.height*0.7215346);
path_1.cubicTo(size.width*0.7284279,size.height*0.7209623,size.width*0.7232090,size.height*0.7150629,size.width*0.7222836,size.height*0.7071761);
path_1.cubicTo(size.width*0.7219104,size.height*0.7039560,size.width*0.7219900,size.height*0.7006289,size.width*0.7219751,size.height*0.6973585);
path_1.cubicTo(size.width*0.7219751,size.height*0.6391509,size.width*0.7219751,size.height*0.5809220,size.width*0.7219751,size.height*0.5227132);
path_1.cubicTo(size.width*0.7219751,size.height*0.5194887,size.width*0.7219751,size.height*0.5162642,size.width*0.7219751,size.height*0.5123616);
path_1.lineTo(size.width*0.6933781,size.height*0.5123616);
path_1.cubicTo(size.width*0.6933781,size.height*0.5154421,size.width*0.6933781,size.height*0.5186057,size.width*0.6933781,size.height*0.5217478);
path_1.cubicTo(size.width*0.6933781,size.height*0.5471761,size.width*0.6935224,size.height*0.5725830,size.width*0.6933134,size.height*0.5980107);
path_1.cubicTo(size.width*0.6931990,size.height*0.6123887,size.width*0.6832338,size.height*0.6206868,size.width*0.6739005,size.height*0.6145453);
path_1.cubicTo(size.width*0.6680000,size.height*0.6106635,size.width*0.6663881,size.height*0.6037415,size.width*0.6663881,size.height*0.5959157);
path_1.cubicTo(size.width*0.6663881,size.height*0.5710428,size.width*0.6663881,size.height*0.5461692,size.width*0.6663881,size.height*0.5212962);
path_1.cubicTo(size.width*0.6663881,size.height*0.5183792,size.width*0.6663881,size.height*0.5154629,size.width*0.6663881,size.height*0.5120943);
path_1.lineTo(size.width*0.6102687,size.height*0.5120943);
path_1.cubicTo(size.width*0.6102687,size.height*0.5154220,size.width*0.6102687,size.height*0.5185849,size.width*0.6102687,size.height*0.5217478);
path_1.cubicTo(size.width*0.6102687,size.height*0.5474428,size.width*0.6103682,size.height*0.5731377,size.width*0.6101891,size.height*0.5988119);
path_1.cubicTo(size.width*0.6101045,size.height*0.6089176,size.width*0.6049055,size.height*0.6158189,size.width*0.5976517,size.height*0.6164962);
path_1.cubicTo(size.width*0.5908756,size.height*0.6171535,size.width*0.5847463,size.height*0.6103553,size.width*0.5835572,size.height*0.6007013);
path_1.cubicTo(size.width*0.5832637,size.height*0.5982987,size.width*0.5833333,size.height*0.5957925,size.width*0.5833333,size.height*0.5933484);
path_1.cubicTo(size.width*0.5833333,size.height*0.5695635,size.width*0.5833333,size.height*0.5457994,size.width*0.5833333,size.height*0.5220151);
path_1.cubicTo(size.width*0.5833333,size.height*0.5190365,size.width*0.5833333,size.height*0.5160377,size.width*0.5833333,size.height*0.5123409);
path_1.lineTo(size.width*0.5554478,size.height*0.5123409);
path_1.cubicTo(size.width*0.5552886,size.height*0.5158535,size.width*0.5549950,size.height*0.5195503,size.width*0.5549950,size.height*0.5232472);
path_1.cubicTo(size.width*0.5549801,size.height*0.5817434,size.width*0.5550249,size.height*0.6402201,size.width*0.5549950,size.height*0.6987170);
path_1.cubicTo(size.width*0.5549950,size.height*0.7120692,size.width*0.5521642,size.height*0.7179811,size.width*0.5449005,size.height*0.7205912);
path_1.cubicTo(size.width*0.5376816,size.height*0.7231761,size.width*0.5300547,size.height*0.7175094,size.width*0.5287562,size.height*0.7082264);
path_1.cubicTo(size.width*0.5281841,size.height*0.7042201,size.width*0.5281045,size.height*0.7000692,size.width*0.5281045,size.height*0.6959811);
path_1.cubicTo(size.width*0.5280746,size.height*0.6385975,size.width*0.5281045,size.height*0.5811893,size.width*0.5281045,size.height*0.5238019);
path_1.cubicTo(size.width*0.5281045,size.height*0.5200226,size.width*0.5281045,size.height*0.5162642,size.width*0.5281045,size.height*0.5120535);
path_1.lineTo(size.width*0.4722935,size.height*0.5120535);
path_1.cubicTo(size.width*0.4721308,size.height*0.5153805,size.width*0.4718706,size.height*0.5185440,size.width*0.4718706,size.height*0.5217069);
path_1.cubicTo(size.width*0.4718383,size.height*0.5454918,size.width*0.4719358,size.height*0.5692560,size.width*0.4718219,size.height*0.5930403);
path_1.cubicTo(size.width*0.4718055,size.height*0.5976208,size.width*0.4717244,size.height*0.6025912,size.width*0.4703587,size.height*0.6066786);
path_1.cubicTo(size.width*0.4680667,size.height*0.6135591,size.width*0.4631731,size.height*0.6168459,size.width*0.4572552,size.height*0.6162704);
path_1.cubicTo(size.width*0.4508010,size.height*0.6156340,size.width*0.4457453,size.height*0.6097390,size.width*0.4455826,size.height*0.6014000);
path_1.cubicTo(size.width*0.4451109,size.height*0.5776358,size.width*0.4452085,size.height*0.5538717,size.width*0.4450950,size.height*0.5300868);
path_1.cubicTo(size.width*0.4450622,size.height*0.5241717,size.width*0.4450950,size.height*0.5182358,size.width*0.4450950,size.height*0.5119711);
path_1.lineTo(size.width*0.4166284,size.height*0.5119711);
path_1.cubicTo(size.width*0.4166284,size.height*0.5150314,size.width*0.4166284,size.height*0.5179069,size.width*0.4166284,size.height*0.5207824);
path_1.cubicTo(size.width*0.4166284,size.height*0.5459226,size.width*0.4167418,size.height*0.5710836,size.width*0.4165955,size.height*0.5962239);
path_1.cubicTo(size.width*0.4165144,size.height*0.6113208,size.width*0.4079303,size.height*0.6199673,size.width*0.3982249,size.height*0.6150384);
path_1.cubicTo(size.width*0.3920144,size.height*0.6118748,size.width*0.3897711,size.height*0.6055075,size.width*0.3897871,size.height*0.5973742);
path_1.cubicTo(size.width*0.3898363,size.height*0.5722340,size.width*0.3898035,size.height*0.5470937,size.width*0.3898035,size.height*0.5219327);
path_1.cubicTo(size.width*0.3898035,size.height*0.5189748,size.width*0.3898035,size.height*0.5160176,size.width*0.3898035,size.height*0.5123000);
path_1.lineTo(size.width*0.3609955,size.height*0.5123000);
path_1.cubicTo(size.width*0.3609955,size.height*0.5157503,size.width*0.3609955,size.height*0.5189547,size.width*0.3609955,size.height*0.5221384);
path_1.cubicTo(size.width*0.3609955,size.height*0.5475660,size.width*0.3610930,size.height*0.5729736,size.width*0.3609303,size.height*0.5984013);
path_1.cubicTo(size.width*0.3608657,size.height*0.6088761,size.width*0.3553866,size.height*0.6161472,size.width*0.3480060,size.height*0.6164553);
path_1.cubicTo(size.width*0.3411940,size.height*0.6167428,size.width*0.3353741,size.height*0.6098006,size.width*0.3343333,size.height*0.6000031);
path_1.cubicTo(size.width*0.3340736,size.height*0.5975799,size.width*0.3341871,size.height*0.5950943,size.width*0.3341871,size.height*0.5926296);
path_1.cubicTo(size.width*0.3341871,size.height*0.5688447,size.width*0.3341871,size.height*0.5450805,size.width*0.3341871,size.height*0.5212962);
path_1.cubicTo(size.width*0.3341871,size.height*0.5183591,size.width*0.3341871,size.height*0.5154421,size.width*0.3341871,size.height*0.5115195);
path_1.cubicTo(size.width*0.3194905,size.height*0.5115195,size.width*0.3054930,size.height*0.5115195,size.width*0.2914955,size.height*0.5115195);
path_1.cubicTo(size.width*0.2824129,size.height*0.5115195,size.width*0.2778771,size.height*0.5172635,size.width*0.2778881,size.height*0.5287522);
path_1.cubicTo(size.width*0.2778881,size.height*0.5850503,size.width*0.2779045,size.height*0.6413522,size.width*0.2778881,size.height*0.6976667);
path_1.cubicTo(size.width*0.2778881,size.height*0.7009371,size.width*0.2779856,size.height*0.7042830,size.width*0.2775627,size.height*0.7074843);
path_1.cubicTo(size.width*0.2765876,size.height*0.7149811,size.width*0.2715149,size.height*0.7206101,size.width*0.2654836,size.height*0.7213270);
path_1.cubicTo(size.width*0.2598259,size.height*0.7220063,size.width*0.2538761,size.height*0.7170189,size.width*0.2522667,size.height*0.7095786);
path_1.cubicTo(size.width*0.2514209,size.height*0.7056981,size.width*0.2511612,size.height*0.7015283,size.width*0.2511612,size.height*0.6974843);
path_1.cubicTo(size.width*0.2510960,size.height*0.6389874,size.width*0.2511448,size.height*0.5699950,size.width*0.2511612,size.height*0.5114987);

Paint paint1Fill = Paint()..style=PaintingStyle.fill;
paint1Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_1,paint1Fill);

Path path_2 = Path();
path_2.moveTo(size.width*0.2511448,size.height*0.4782868);
path_2.cubicTo(size.width*0.2508522,size.height*0.4312717,size.width*0.2511612,size.height*0.3736792,size.width*0.2512423,size.height*0.3266642);
path_2.cubicTo(size.width*0.2512423,size.height*0.3228849,size.width*0.2514866,size.height*0.3190031,size.width*0.2522343,size.height*0.3153679);
path_2.cubicTo(size.width*0.2537786,size.height*0.3077270,size.width*0.2593711,size.height*0.3025717,size.width*0.2650612,size.height*0.3029208);
path_2.cubicTo(size.width*0.2714831,size.height*0.3033113,size.width*0.2768965,size.height*0.3096170,size.width*0.2776930,size.height*0.3178943);
path_2.cubicTo(size.width*0.2779856,size.height*0.3208723,size.width*0.2778881,size.height*0.3238918,size.width*0.2778881,size.height*0.3269107);
path_2.cubicTo(size.width*0.2779045,size.height*0.3736384,size.width*0.2779045,size.height*0.4203862,size.width*0.2779209,size.height*0.4671132);
path_2.cubicTo(size.width*0.2779209,size.height*0.4744528,size.width*0.2809119,size.height*0.4781289,size.width*0.2868950,size.height*0.4781428);
path_2.cubicTo(size.width*0.3005184,size.height*0.4781428,size.width*0.3141582,size.height*0.4778553,size.width*0.3277821,size.height*0.4782453);
path_2.cubicTo(size.width*0.3329194,size.height*0.4783893,size.width*0.3343662,size.height*0.4763352,size.width*0.3343498,size.height*0.4698654);
path_2.cubicTo(size.width*0.3341547,size.height*0.4220289,size.width*0.3342363,size.height*0.3742132,size.width*0.3342851,size.height*0.3263767);
path_2.cubicTo(size.width*0.3342851,size.height*0.3231314,size.width*0.3343990,size.height*0.3198044,size.width*0.3349677,size.height*0.3166616);
path_2.cubicTo(size.width*0.3365124,size.height*0.3080969,size.width*0.3422025,size.height*0.3024277,size.width*0.3483149,size.height*0.3029208);
path_2.cubicTo(size.width*0.3552896,size.height*0.3034962,size.width*0.3607030,size.height*0.3102535,size.width*0.3608657,size.height*0.3197013);
path_2.cubicTo(size.width*0.3611423,size.height*0.3366465,size.width*0.3609960,size.height*0.3535918,size.width*0.3610119,size.height*0.3705365);
path_2.cubicTo(size.width*0.3610119,size.height*0.4033384,size.width*0.3611746,size.height*0.4361396,size.width*0.3608980,size.height*0.4689208);
path_2.cubicTo(size.width*0.3608333,size.height*0.4761094,size.width*0.3624587,size.height*0.4789025,size.width*0.3682139,size.height*0.4781836);
path_2.cubicTo(size.width*0.3725060,size.height*0.4776497,size.width*0.3768632,size.height*0.4780811,size.width*0.3811876,size.height*0.4780811);
path_2.cubicTo(size.width*0.3869318,size.height*0.4780673,size.width*0.3898095,size.height*0.4745346,size.width*0.3898199,size.height*0.4674830);
path_2.cubicTo(size.width*0.3898199,size.height*0.4193792,size.width*0.3898199,size.height*0.3712761,size.width*0.3898687,size.height*0.3231730);
path_2.cubicTo(size.width*0.3898687,size.height*0.3126774,size.width*0.3926488,size.height*0.3068642,size.width*0.3985990,size.height*0.3041535);
path_2.cubicTo(size.width*0.4058662,size.height*0.3008465,size.width*0.4133607,size.height*0.3053855,size.width*0.4155065,size.height*0.3148132);
path_2.cubicTo(size.width*0.4163194,size.height*0.3184075,size.width*0.4165796,size.height*0.3223308,size.width*0.4165796,size.height*0.3261101);
path_2.cubicTo(size.width*0.4166607,size.height*0.3731245,size.width*0.4166284,size.height*0.4201396,size.width*0.4166448,size.height*0.4671340);
path_2.cubicTo(size.width*0.4166448,size.height*0.4703585,size.width*0.4166448,size.height*0.4735623,size.width*0.4166448,size.height*0.4779786);
path_2.cubicTo(size.width*0.4254398,size.height*0.4779786,size.width*0.4336010,size.height*0.4782868,size.width*0.4416970,size.height*0.4776497);
path_2.cubicTo(size.width*0.4429328,size.height*0.4775472,size.width*0.4449000,size.height*0.4731314,size.width*0.4449488,size.height*0.4706667);
path_2.cubicTo(size.width*0.4452413,size.height*0.4540088,size.width*0.4451274,size.height*0.4373308,size.width*0.4451274,size.height*0.4206528);
path_2.cubicTo(size.width*0.4451274,size.height*0.3892277,size.width*0.4450950,size.height*0.3577818,size.width*0.4452090,size.height*0.3263566);
path_2.cubicTo(size.width*0.4452249,size.height*0.3217761,size.width*0.4452736,size.height*0.3168057,size.width*0.4466234,size.height*0.3127182);
path_2.cubicTo(size.width*0.4488990,size.height*0.3058170,size.width*0.4537925,size.height*0.3025308,size.width*0.4596940,size.height*0.3030849);
path_2.cubicTo(size.width*0.4659209,size.height*0.3036604,size.width*0.4704891,size.height*0.3094113,size.width*0.4713343,size.height*0.3171755);
path_2.cubicTo(size.width*0.4717408,size.height*0.3209547,size.width*0.4718219,size.height*0.3247956,size.width*0.4718383,size.height*0.3286157);
path_2.cubicTo(size.width*0.4718706,size.height*0.3750761,size.width*0.4720010,size.height*0.4215358,size.width*0.4717572,size.height*0.4679962);
path_2.cubicTo(size.width*0.4717244,size.height*0.4756987,size.width*0.4732204,size.height*0.4785126,size.width*0.4796582,size.height*0.4782252);
path_2.cubicTo(size.width*0.4932657,size.height*0.4776088,size.width*0.5069204,size.height*0.4776704,size.width*0.5205274,size.height*0.4781836);
path_2.cubicTo(size.width*0.5264627,size.height*0.4784101,size.width*0.5282836,size.height*0.4761503,size.width*0.5282537,size.height*0.4685918);
path_2.cubicTo(size.width*0.5280249,size.height*0.4218648,size.width*0.5281542,size.height*0.3751170,size.width*0.5282040,size.height*0.3283899);
path_2.cubicTo(size.width*0.5282040,size.height*0.3245692,size.width*0.5282836,size.height*0.3207283,size.width*0.5287214,size.height*0.3169491);
path_2.cubicTo(size.width*0.5296667,size.height*0.3087950,size.width*0.5355025,size.height*0.3026333,size.width*0.5417761,size.height*0.3028182);
path_2.cubicTo(size.width*0.5479055,size.height*0.3029824,size.width*0.5534179,size.height*0.3088981,size.width*0.5543781,size.height*0.3166824);
path_2.cubicTo(size.width*0.5548308,size.height*0.3204409,size.width*0.5549453,size.height*0.3243025,size.width*0.5549453,size.height*0.3281025);
path_2.cubicTo(size.width*0.5549950,size.height*0.3740283,size.width*0.5549801,size.height*0.4199340,size.width*0.5550100,size.height*0.4658604);
path_2.cubicTo(size.width*0.5550100,size.height*0.4696189,size.width*0.5552687,size.height*0.4733572,size.width*0.5554328,size.height*0.4775472);
path_2.lineTo(size.width*0.5833632,size.height*0.4775472);
path_2.cubicTo(size.width*0.5833632,size.height*0.4740145,size.width*0.5833632,size.height*0.4708516,size.width*0.5833632,size.height*0.4677088);
path_2.cubicTo(size.width*0.5833632,size.height*0.4212484,size.width*0.5833632,size.height*0.3747881,size.width*0.5833632,size.height*0.3283283);
path_2.cubicTo(size.width*0.5833632,size.height*0.3261509,size.width*0.5832985,size.height*0.3239535,size.width*0.5833980,size.height*0.3217761);
path_2.cubicTo(size.width*0.5838507,size.height*0.3103975,size.width*0.5895423,size.height*0.3025925,size.width*0.5971642,size.height*0.3028182);
path_2.cubicTo(size.width*0.6049701,size.height*0.3030648,size.width*0.6102189,size.height*0.3106642,size.width*0.6102388,size.height*0.3223925);
path_2.cubicTo(size.width*0.6103184,size.height*0.3710503,size.width*0.6103980,size.height*0.4196874,size.width*0.6101891,size.height*0.4683453);
path_2.cubicTo(size.width*0.6101542,size.height*0.4756371,size.width*0.6115224,size.height*0.4783893,size.width*0.6177015,size.height*0.4781836);
path_2.cubicTo(size.width*0.6336318,size.height*0.4776497,size.width*0.6495970,size.height*0.4779987,size.width*0.6664229,size.height*0.4779987);
path_2.cubicTo(size.width*0.6664229,size.height*0.4738296,size.width*0.6664229,size.height*0.4706459,size.width*0.6664229,size.height*0.4674623);
path_2.cubicTo(size.width*0.6664229,size.height*0.4204478,size.width*0.6664080,size.height*0.3734327,size.width*0.6664876,size.height*0.3264384);
path_2.cubicTo(size.width*0.6664876,size.height*0.3223925,size.width*0.6667662,size.height*0.3182019,size.width*0.6676418,size.height*0.3143409);
path_2.cubicTo(size.width*0.6693184,size.height*0.3070289,size.width*0.6754129,size.height*0.3021403,size.width*0.6810547,size.height*0.3029000);
path_2.cubicTo(size.width*0.6871343,size.height*0.3037220,size.width*0.6921095,size.height*0.3093088,size.width*0.6930498,size.height*0.3168465);
path_2.cubicTo(size.width*0.6934577,size.height*0.3200509,size.width*0.6933781,size.height*0.3233780,size.width*0.6933781,size.height*0.3266642);
path_2.cubicTo(size.width*0.6933930,size.height*0.3739459,size.width*0.6935373,size.height*0.4212283,size.width*0.6932786,size.height*0.4685101);
path_2.cubicTo(size.width*0.6932289,size.height*0.4761094,size.width*0.6949701,size.height*0.4788000,size.width*0.7009353,size.height*0.4780811);
path_2.cubicTo(size.width*0.7056517,size.height*0.4775063,size.width*0.7104776,size.height*0.4775679,size.width*0.7151940,size.height*0.4780811);
path_2.cubicTo(size.width*0.7206716,size.height*0.4786767,size.width*0.7221343,size.height*0.4759453,size.width*0.7221045,size.height*0.4692289);
path_2.cubicTo(size.width*0.7219104,size.height*0.4219472,size.width*0.7220050,size.height*0.3746654,size.width*0.7220249,size.height*0.3273830);
path_2.cubicTo(size.width*0.7220249,size.height*0.3240969,size.width*0.7219403,size.height*0.3207899,size.width*0.7222836,size.height*0.3175654);
path_2.cubicTo(size.width*0.7231095,size.height*0.3095755,size.width*0.7281194,size.height*0.3036805,size.width*0.7344279,size.height*0.3028799);
path_2.cubicTo(size.width*0.7403433,size.height*0.3021403,size.width*0.7463284,size.height*0.3073164,size.width*0.7479701,size.height*0.3151830);
path_2.cubicTo(size.width*0.7487313,size.height*0.3188182,size.width*0.7489453,size.height*0.3227208,size.width*0.7489453,size.height*0.3265000);
path_2.cubicTo(size.width*0.7490100,size.height*0.3732270,size.width*0.7489950,size.height*0.4199748,size.width*0.7489950,size.height*0.4667025);
path_2.cubicTo(size.width*0.7489950,size.height*0.4699478,size.width*0.7489950,size.height*0.4732132,size.width*0.7489950,size.height*0.4775264);

Paint paint2Fill = Paint()..style=PaintingStyle.fill;
paint2Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_2,paint2Fill);

Path path_3 = Path();
path_3.moveTo(size.width*0.1677448,size.height*0.7023711);
path_3.cubicTo(size.width*0.1682488,size.height*0.7012201,size.width*0.1688174,size.height*0.7000943,size.width*0.1692567,size.height*0.6988805);
path_3.cubicTo(size.width*0.1722154,size.height*0.6906667,size.width*0.1779706,size.height*0.6865535,size.width*0.1842945,size.height*0.6882201);
path_3.cubicTo(size.width*0.1903259,size.height*0.6897987,size.width*0.1946020,size.height*0.6961509,size.width*0.1947318,size.height*0.7047736);
path_3.cubicTo(size.width*0.1949592,size.height*0.7197862,size.width*0.1948294,size.height*0.7348050,size.width*0.1948458,size.height*0.7498176);
path_3.cubicTo(size.width*0.1948781,size.height*0.7791509,size.width*0.2057219,size.height*0.7927484,size.width*0.2291000,size.height*0.7927484);
path_3.cubicTo(size.width*0.2405612,size.height*0.7927484,size.width*0.2520065,size.height*0.7926038,size.width*0.2634517,size.height*0.7928050);
path_3.cubicTo(size.width*0.2719866,size.height*0.7929497,size.width*0.2775303,size.height*0.7993396,size.width*0.2778393,size.height*0.8087862);
path_3.cubicTo(size.width*0.2781483,size.height*0.8185660,size.width*0.2727184,size.height*0.8263082,size.width*0.2640045,size.height*0.8264088);
path_3.cubicTo(size.width*0.2480398,size.height*0.8265975,size.width*0.2319935,size.height*0.8269245,size.width*0.2161264,size.height*0.8251132);
path_3.cubicTo(size.width*0.1914154,size.height*0.8223019,size.width*0.1725408,size.height*0.7979434,size.width*0.1691104,size.height*0.7667862);
path_3.cubicTo(size.width*0.1689149,size.height*0.7649560,size.width*0.1682159,size.height*0.7632075,size.width*0.1677448,size.height*0.7614214);
path_3.cubicTo(size.width*0.1677448,size.height*0.7417484,size.width*0.1677448,size.height*0.7220692,size.width*0.1677448,size.height*0.7023899);
path_3.lineTo(size.width*0.1677448,size.height*0.7023711);
path_3.close();

Paint paint3Fill = Paint()..style=PaintingStyle.fill;
paint3Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_3,paint3Fill);

Path path_4 = Path();
path_4.moveTo(size.width*0.1677448,size.height*0.2628692);
path_4.cubicTo(size.width*0.1696791,size.height*0.2545918,size.width*0.1707846,size.height*0.2458006,size.width*0.1736950,size.height*0.2381189);
path_4.cubicTo(size.width*0.1835791,size.height*0.2120340,size.width*0.2007796,size.height*0.1991761,size.width*0.2232960,size.height*0.1979233);
path_4.cubicTo(size.width*0.2364647,size.height*0.1972044,size.width*0.2496816,size.height*0.1976151,size.width*0.2628826,size.height*0.1978208);
path_4.cubicTo(size.width*0.2688164,size.height*0.1979233,size.width*0.2747502,size.height*0.2002648,size.width*0.2763109,size.height*0.2080491);
path_4.cubicTo(size.width*0.2773517,size.height*0.2132044,size.width*0.2769129,size.height*0.2205164,size.width*0.2746204,size.height*0.2245836);
path_4.cubicTo(size.width*0.2724582,size.height*0.2284038,size.width*0.2670607,size.height*0.2308277,size.width*0.2629801,size.height*0.2311151);
path_4.cubicTo(size.width*0.2509010,size.height*0.2319365,size.width*0.2387731,size.height*0.2313616,size.width*0.2266448,size.height*0.2314233);
path_4.cubicTo(size.width*0.2064373,size.height*0.2315465,size.width*0.1948945,size.height*0.2461497,size.width*0.1947970,size.height*0.2717214);
path_4.cubicTo(size.width*0.1947483,size.height*0.2853799,size.width*0.1947970,size.height*0.2990591,size.width*0.1947970,size.height*0.3127182);
path_4.cubicTo(size.width*0.1947970,size.height*0.3268289,size.width*0.1920169,size.height*0.3333195,size.width*0.1849935,size.height*0.3357635);
path_4.cubicTo(size.width*0.1780841,size.height*0.3381667,size.width*0.1729144,size.height*0.3340176,size.width*0.1677607,size.height*0.3218994);
path_4.cubicTo(size.width*0.1677607,size.height*0.3022226,size.width*0.1677607,size.height*0.2825459,size.width*0.1677607,size.height*0.2628692);
path_4.lineTo(size.width*0.1677448,size.height*0.2628692);
path_4.close();

Paint paint4Fill = Paint()..style=PaintingStyle.fill;
paint4Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_4,paint4Fill);

Path path_5 = Path();
path_5.moveTo(size.width*0.8051144,size.height*0.7302830);
path_5.cubicTo(size.width*0.8051144,size.height*0.7218239,size.width*0.8049204,size.height*0.7133585,size.width*0.8051642,size.height*0.7049182);
path_5.cubicTo(size.width*0.8054577,size.height*0.6951195,size.width*0.8103333,size.height*0.6885283,size.width*0.8173234,size.height*0.6878113);
path_5.cubicTo(size.width*0.8245075,size.height*0.6870692,size.width*0.8313035,size.height*0.6924277,size.width*0.8314030,size.height*0.7019623);
path_5.cubicTo(size.width*0.8316617,size.height*0.7261384,size.width*0.8329950,size.height*0.7508868,size.width*0.8294975,size.height*0.7743648);
path_5.cubicTo(size.width*0.8247065,size.height*0.8065660,size.width*0.8028557,size.height*0.8258113,size.width*0.7761592,size.height*0.8266541);
path_5.cubicTo(size.width*0.7634279,size.height*0.8270692,size.width*0.7506667,size.height*0.8268616,size.width*0.7379403,size.height*0.8266792);
path_5.cubicTo(size.width*0.7282189,size.height*0.8265535,size.width*0.7222189,size.height*0.8199182,size.width*0.7221194,size.height*0.8096918);
path_5.cubicTo(size.width*0.7220249,size.height*0.7991132,size.width*0.7280547,size.height*0.7926226,size.width*0.7382786,size.height*0.7925409);
path_5.cubicTo(size.width*0.7501642,size.height*0.7924403,size.width*0.7620299,size.height*0.7926038,size.width*0.7739154,size.height*0.7924780);
path_5.cubicTo(size.width*0.7934428,size.height*0.7922956,size.width*0.8048706,size.height*0.7778113,size.width*0.8050498,size.height*0.7531887);
path_5.cubicTo(size.width*0.8051144,size.height*0.7455472,size.width*0.8050498,size.height*0.7379057,size.width*0.8050498,size.height*0.7302642);
path_5.cubicTo(size.width*0.8050647,size.height*0.7302642,size.width*0.8050796,size.height*0.7302642,size.width*0.8051144,size.height*0.7302642);
path_5.lineTo(size.width*0.8051144,size.height*0.7302830);
path_5.close();

Paint paint5Fill = Paint()..style=PaintingStyle.fill;
paint5Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_5,paint5Fill);

Path path_6 = Path();
path_6.moveTo(size.width*0.8050995,size.height*0.2925692);
path_6.cubicTo(size.width*0.8050995,size.height*0.2860170,size.width*0.8050995,size.height*0.2794648,size.width*0.8050995,size.height*0.2728925);
path_6.cubicTo(size.width*0.8050498,size.height*0.2460063,size.width*0.7939104,size.height*0.2317723,size.width*0.7727960,size.height*0.2316698);
path_6.cubicTo(size.width*0.7611194,size.height*0.2316082,size.width*0.7494478,size.height*0.2317314,size.width*0.7377761,size.height*0.2316082);
path_6.cubicTo(size.width*0.7279751,size.height*0.2315050,size.width*0.7220896,size.height*0.2249736,size.width*0.7221692,size.height*0.2146013);
path_6.cubicTo(size.width*0.7222488,size.height*0.2046189,size.width*0.7280697,size.height*0.1976975,size.width*0.7373532,size.height*0.1976767);
path_6.cubicTo(size.width*0.7524726,size.height*0.1976560,size.width*0.7677065,size.height*0.1967522,size.width*0.7826766,size.height*0.1988270);
path_6.cubicTo(size.width*0.8118607,size.height*0.2028730,size.width*0.8307512,size.height*0.2296157,size.width*0.8320050,size.height*0.2670384);
path_6.cubicTo(size.width*0.8325572,size.height*0.2839421,size.width*0.8323134,size.height*0.3009082,size.width*0.8320547,size.height*0.3178327);
path_6.cubicTo(size.width*0.8318756,size.height*0.3294371,size.width*0.8262139,size.height*0.3366673,size.width*0.8182488,size.height*0.3364824);
path_6.cubicTo(size.width*0.8102687,size.height*0.3362975,size.width*0.8053433,size.height*0.3290472,size.width*0.8051294,size.height*0.3171340);
path_6.cubicTo(size.width*0.8050995,size.height*0.3154912,size.width*0.8051294,size.height*0.3138478,size.width*0.8051294,size.height*0.3122252);
path_6.cubicTo(size.width*0.8051294,size.height*0.3056730,size.width*0.8051294,size.height*0.2991208,size.width*0.8051294,size.height*0.2925484);
path_6.lineTo(size.width*0.8050995,size.height*0.2925692);
path_6.close();

Paint paint6Fill = Paint()..style=PaintingStyle.fill;
paint6Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_6,paint6Fill);

Path path_7 = Path();
path_7.moveTo(size.width*0.6102388,size.height*0.6875409);
path_7.cubicTo(size.width*0.6102388,size.height*0.6935409,size.width*0.6104975,size.height*0.6995597,size.width*0.6101741,size.height*0.7055157);
path_7.cubicTo(size.width*0.6097015,size.height*0.7144088,size.width*0.6044677,size.height*0.7208365,size.width*0.5977214,size.height*0.7214969);
path_7.cubicTo(size.width*0.5915920,size.height*0.7220881,size.width*0.5848458,size.height*0.7165849,size.width*0.5843383,size.height*0.7081447);
path_7.cubicTo(size.width*0.5834925,size.height*0.6941384,size.width*0.5834279,size.height*0.6798994,size.width*0.5843881,size.height*0.6659119);
path_7.cubicTo(size.width*0.5850199,size.height*0.6566918,size.width*0.5911493,size.height*0.6522767,size.width*0.5984527,size.height*0.6531195);
path_7.cubicTo(size.width*0.6050050,size.height*0.6538553,size.width*0.6095721,size.height*0.6599182,size.width*0.6102388,size.height*0.6687673);
path_7.cubicTo(size.width*0.6102886,size.height*0.6693019,size.width*0.6103035,size.height*0.6698553,size.width*0.6103184,size.height*0.6703899);
path_7.cubicTo(size.width*0.6103184,size.height*0.6761195,size.width*0.6103184,size.height*0.6818302,size.width*0.6103184,size.height*0.6875660);
path_7.cubicTo(size.width*0.6102886,size.height*0.6875660,size.width*0.6102687,size.height*0.6875660,size.width*0.6102388,size.height*0.6875660);
path_7.lineTo(size.width*0.6102388,size.height*0.6875409);
path_7.close();

Paint paint7Fill = Paint()..style=PaintingStyle.fill;
paint7Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_7,paint7Fill);

Path path_8 = Path();
path_8.moveTo(size.width*0.6933433,size.height*0.6873145);
path_8.cubicTo(size.width*0.6933433,size.height*0.6933145,size.width*0.6935871,size.height*0.6993333,size.width*0.6932786,size.height*0.7053082);
path_8.cubicTo(size.width*0.6928259,size.height*0.7143082,size.width*0.6877861,size.height*0.7206730,size.width*0.6809751,size.height*0.7214969);
path_8.cubicTo(size.width*0.6746020,size.height*0.7222516,size.width*0.6677711,size.height*0.7165220,size.width*0.6672537,size.height*0.7076289);
path_8.cubicTo(size.width*0.6664378,size.height*0.6938679,size.width*0.6664229,size.height*0.6798805,size.width*0.6673632,size.height*0.6661384);
path_8.cubicTo(size.width*0.6680000,size.height*0.6569371,size.width*0.6741294,size.height*0.6523585,size.width*0.6813483,size.height*0.6530755);
path_8.cubicTo(size.width*0.6879453,size.height*0.6537358,size.width*0.6927761,size.height*0.6597296,size.width*0.6932637,size.height*0.6685409);
path_8.cubicTo(size.width*0.6936070,size.height*0.6747862,size.width*0.6933284,size.height*0.6810755,size.width*0.6933284,size.height*0.6873585);
path_8.cubicTo(size.width*0.6933284,size.height*0.6873585,size.width*0.6933284,size.height*0.6873585,size.width*0.6933433,size.height*0.6873585);
path_8.lineTo(size.width*0.6933433,size.height*0.6873145);
path_8.close();

Paint paint8Fill = Paint()..style=PaintingStyle.fill;
paint8Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_8,paint8Fill);

Path path_9 = Path();
path_9.moveTo(size.width*0.3899338,size.height*0.6865346);
path_9.cubicTo(size.width*0.3899338,size.height*0.6805409,size.width*0.3896736,size.height*0.6744969,size.width*0.3899985,size.height*0.6685220);
path_9.cubicTo(size.width*0.3904866,size.height*0.6597296,size.width*0.3953801,size.height*0.6537170,size.width*0.4019642,size.height*0.6531384);
path_9.cubicTo(size.width*0.4090363,size.height*0.6525220,size.width*0.4150189,size.height*0.6567925,size.width*0.4156040,size.height*0.6656478);
path_9.cubicTo(size.width*0.4165308,size.height*0.6799245,size.width*0.4164333,size.height*0.6944465,size.width*0.4155716,size.height*0.7087421);
path_9.cubicTo(size.width*0.4150836,size.height*0.7167296,size.width*0.4083209,size.height*0.7219874,size.width*0.4024194,size.height*0.7214151);
path_9.cubicTo(size.width*0.3959000,size.height*0.7207736,size.width*0.3905841,size.height*0.7145723,size.width*0.3900637,size.height*0.7061698);
path_9.cubicTo(size.width*0.3896572,size.height*0.6996604,size.width*0.3899826,size.height*0.6930881,size.width*0.3899826,size.height*0.6865346);
path_9.cubicTo(size.width*0.3899826,size.height*0.6865346,size.width*0.3899498,size.height*0.6865346,size.width*0.3899338,size.height*0.6865346);
path_9.close();

Paint paint9Fill = Paint()..style=PaintingStyle.fill;
paint9Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_9,paint9Fill);

Path path_10 = Path();
path_10.moveTo(size.width*0.3609796,size.height*0.6875409);
path_10.cubicTo(size.width*0.3609796,size.height*0.6932704,size.width*0.3611746,size.height*0.6990063,size.width*0.3609308,size.height*0.7047107);
path_10.cubicTo(size.width*0.3605244,size.height*0.7141195,size.width*0.3553055,size.height*0.7208553,size.width*0.3483313,size.height*0.7214151);
path_10.cubicTo(size.width*0.3422020,size.height*0.7219057,size.width*0.3356179,size.height*0.7163208,size.width*0.3351139,size.height*0.7077736);
path_10.cubicTo(size.width*0.3342851,size.height*0.6940126,size.width*0.3342199,size.height*0.6800252,size.width*0.3351627,size.height*0.6662830);
path_10.cubicTo(size.width*0.3357970,size.height*0.6569182,size.width*0.3417468,size.height*0.6524843,size.width*0.3490791,size.height*0.6531824);
path_10.cubicTo(size.width*0.3558582,size.height*0.6538365,size.width*0.3605891,size.height*0.6601447,size.width*0.3609632,size.height*0.6695283);
path_10.cubicTo(size.width*0.3611910,size.height*0.6755094,size.width*0.3610119,size.height*0.6815220,size.width*0.3609955,size.height*0.6875220);
path_10.lineTo(size.width*0.3609796,size.height*0.6875409);
path_10.close();

Paint paint10Fill = Paint()..style=PaintingStyle.fill;
paint10Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_10,paint10Fill);

Path path_11 = Path();
path_11.moveTo(size.width*0.4715129,size.height*0.6868616);
path_11.cubicTo(size.width*0.4715129,size.height*0.6934151,size.width*0.4718871,size.height*0.7000126,size.width*0.4714154,size.height*0.7065031);
path_11.cubicTo(size.width*0.4707652,size.height*0.7152893,size.width*0.4648965,size.height*0.7216352,size.width*0.4583607,size.height*0.7215157);
path_11.cubicTo(size.width*0.4520045,size.height*0.7213899,size.width*0.4459891,size.height*0.7152893,size.width*0.4456801,size.height*0.7069748);
path_11.cubicTo(size.width*0.4451925,size.height*0.6936415,size.width*0.4451597,size.height*0.6802327,size.width*0.4457289,size.height*0.6669182);
path_11.cubicTo(size.width*0.4461030,size.height*0.6582767,size.width*0.4517602,size.height*0.6529937,size.width*0.4586373,size.height*0.6530755);
path_11.cubicTo(size.width*0.4654980,size.height*0.6531572,size.width*0.4706512,size.height*0.6584969,size.width*0.4713507,size.height*0.6672893);
path_11.cubicTo(size.width*0.4718706,size.height*0.6737610,size.width*0.4714483,size.height*0.6803711,size.width*0.4714483,size.height*0.6869057);
path_11.cubicTo(size.width*0.4714642,size.height*0.6869057,size.width*0.4714806,size.height*0.6869057,size.width*0.4714970,size.height*0.6869057);
path_11.lineTo(size.width*0.4715129,size.height*0.6868616);
path_11.close();

Paint paint11Fill = Paint()..style=PaintingStyle.fill;
paint11Fill.color = const Color(0xff1F1F3D).withOpacity(1.0);
canvas.drawPath(path_11,paint11Fill);

Path path_12 = Path();
path_12.moveTo(size.width*0.8243483,size.height*0.4724327);
path_12.lineTo(size.width*0.1757269,size.height*0.4724327);
path_12.cubicTo(size.width*0.1684184,size.height*0.4724327,size.width*0.1624935,size.height*0.4799182,size.width*0.1624935,size.height*0.4891522);
path_12.lineTo(size.width*0.1624935,size.height*0.4950057);
path_12.cubicTo(size.width*0.1624935,size.height*0.5042396,size.width*0.1684184,size.height*0.5117245,size.width*0.1757269,size.height*0.5117245);
path_12.lineTo(size.width*0.8243483,size.height*0.5117245);
path_12.cubicTo(size.width*0.8316567,size.height*0.5117245,size.width*0.8375821,size.height*0.5042396,size.width*0.8375821,size.height*0.4950057);
path_12.lineTo(size.width*0.8375821,size.height*0.4891522);
path_12.cubicTo(size.width*0.8375821,size.height*0.4799182,size.width*0.8316567,size.height*0.4724327,size.width*0.8243483,size.height*0.4724327);
path_12.close();

Paint paint12Fill = Paint()..style=PaintingStyle.fill;
paint12Fill.color = const Color(0xff5459FA).withOpacity(1.0);
canvas.drawPath(path_12,paint12Fill);

}

@override
bool shouldRepaint(covariant CustomPainter oldDelegate) {
return true;
}
}