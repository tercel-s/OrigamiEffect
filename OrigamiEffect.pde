PImage  img;
Origami origami;

// 400x300, P3Dモードですよー。
void setup() {
  size(400, 300, P3D);
  noStroke();
  
  img = loadImage("background.png");
  origami = new Origami(250, 250, 0);
}

void draw() {
  background(30);
  lights();
  
  float angle = 0.3 * radians(frameCount);
  camera(500, 500, 500,
           0,   0,   0, 
           0,  -1,   0);
  rotateY(angle);
    
  origami = origami.update();
}

// テクスチャ座標を保持するクラス
class TextureCoords {
  final int NUM_COORDS = 4;
  public PVector[] uvCoords;
  TextureCoords() {
    uvCoords = new PVector[NUM_COORDS];
    for(int i = 0; i < NUM_COORDS; ++i) {
      uvCoords[i] = new PVector();
    }
  }
}

class Origami {
  private float _width;
  private float _height;
  
  private float _angle;
  private int   _count;
  private int   _direction;
  
  private float _scale;
  
  private TextureCoords _entireTexCoords;
  private TextureCoords _innerTexCoords1;
  private TextureCoords _innerTexCoords2;
  private TextureCoords _outerTexCoords;
  
  Origami(float w, float h, int dir) {
    // サイズを設定
    _width  = w;
    _height = h;
    
    // 紙を開く方向を設定
    _direction = dir;
    
    // カウンタを0クリア
    _count  = 0;
    _scale  = dir % 2 == 0 ? 1 : 0.75;
    
    // テクスチャ座標保持オブジェクト
    _entireTexCoords = new TextureCoords();
    _innerTexCoords1 = new TextureCoords();
    _innerTexCoords2 = new TextureCoords();
    _outerTexCoords  = new TextureCoords(); 
  }
  
  // テクスチャ座標保持オブジェクトをセットアップ
  private void initEntireTexCoords() {
    _entireTexCoords.uvCoords[0] = new PVector(0, 0);
    _entireTexCoords.uvCoords[1] = new PVector(0, img.height);
    _entireTexCoords.uvCoords[2] = new PVector(img.width, img.height);
    _entireTexCoords.uvCoords[3] = new PVector(img.width, 0);
  }
  
  // 更新
  Origami update() {
    if(_count == 0) initEntireTexCoords();
    
    // 紙をめくる角度
    _angle = radians(_count);
    
    // 符号
    int sign = _direction < 2 ? -1 : 1;    
    
    pushMatrix();
    
    // 紙が画面からはみ出ないように、さりげなくスケーリングを適用する。
    float newScale = _scale - _count * 0.25 / 180.0;
    scale(newScale);
    
    // 注視点が常に重心を追尾するよう再計算を行い並進移動する。
    float offsetX = _direction % 2 == 0 ? sign * _count / 180.0f * _width : 0;
    float offsetZ = _direction % 2 == 0 ? 0 : sign * _count / 180.0f * _height;
    translate(offsetX, 0, offsetZ);
    
    // 内側のテクスチャ座標を計算
    getInnerTextureCoords(_direction,
      _entireTexCoords,
      _innerTexCoords1,
      _innerTexCoords2);

    // 外側のテクスチャ座標を計算
    getOuterTextureCoords(_direction,
      _entireTexCoords,
      _outerTexCoords);
    
    // 折り重なる紙を描く。
    for(int i : new int[]{0, 1}) {
      pushMatrix();
      
      // うち1枚目だけは、紙を折り開くアニメーションのために並進 + 回転運動を適用する。
      if(i % 2 == 0) {
        offsetX = _direction % 2 == 0 ? sign * _width : 0;
        offsetZ = _direction % 2 == 0 ? 0 : sign * _height;
        _angle = sign * radians(_count);
      } else {
        offsetX = 0;
        offsetZ = 0;
        _angle = PI;
      }
      
      // 紙をパタンと開くアニメーション
      translate(-offsetX, 0, -offsetZ);
      if (_direction % 2 == 0) 
        rotateZ(_angle);
      else {
        rotateX(-_angle);
      }
      translate(offsetX, 0, offsetZ);
      
      // どの方向から開いても、テクスチャの上下左右の方向が揃うよう
      // Y軸まわりの回転補正。
      rotateY(_direction % 2 == 0 ? 0 : PI );
      
      // テクスチャを内と外で描き分ける
      for(int j : new int[] {0, 1}) {
        beginShape();
        texture(img);
        TextureCoords _coords = j > 0 ? _outerTexCoords : i % 2 == 0 ? _innerTexCoords1 : _innerTexCoords2;
        vertex(-_width, 0.2 * j, -_height, _coords.uvCoords[0].x, _coords.uvCoords[0].y);
        vertex(-_width, 0.2 * j,  _height, _coords.uvCoords[1].x, _coords.uvCoords[1].y);
        vertex( _width, 0.2 * j,  _height, _coords.uvCoords[2].x, _coords.uvCoords[2].y);
        vertex( _width, 0.2 * j, -_height, _coords.uvCoords[3].x, _coords.uvCoords[3].y);
        endShape(CLOSE);
      }
      
      popMatrix();
    }
    popMatrix();

    // 遷移制御。
    if(++_count < 180) return this;
    
    // 180度パタンと開いたら、次の状態へ遷移する。
    float newWidth  = _direction % 2 == 0 ? 2 *_width : _width / 2;
    float newHeight = _height;
    return new Origami(newWidth, newHeight, ++_direction % 4);
  }
  
  // テクスチャのUV座標を求める
  void getOuterTextureCoords(int direction,
    TextureCoords entireCoords,
    TextureCoords outerCoords) {
      
      if(direction % 2 == 0) {
        outerCoords.uvCoords[0].set(entireCoords.uvCoords[3]);
        outerCoords.uvCoords[1].set(entireCoords.uvCoords[2]);
        outerCoords.uvCoords[2].set(entireCoords.uvCoords[1]);
        outerCoords.uvCoords[3].set(entireCoords.uvCoords[0]);
        
      } else {
        outerCoords.uvCoords[0].set(entireCoords.uvCoords[1]);
        outerCoords.uvCoords[1].set(entireCoords.uvCoords[0]);
        outerCoords.uvCoords[2].set(entireCoords.uvCoords[3]);
        outerCoords.uvCoords[3].set(entireCoords.uvCoords[2]);
      }
  }
  
  // テクスチャのUV座標を求める
  // ここソースがカオスすぎる…。
  void getInnerTextureCoords(int direction,
    TextureCoords entireCoords,
    TextureCoords innerCoords1,
    TextureCoords innerCoords2) {
      
      if(direction == 0) {
        innerCoords1.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords1.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords1.uvCoords[2].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[2].y);
        innerCoords1.uvCoords[3].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[3].y);
        
        innerCoords2.uvCoords[0].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[0].y);
        innerCoords2.uvCoords[1].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[1].y);
        innerCoords2.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords2.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
      } else if(direction == 1) {
        innerCoords1.uvCoords[0].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords1.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords1.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords1.uvCoords[3].set(entireCoords.uvCoords[3].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
        
        innerCoords2.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords2.uvCoords[1].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords2.uvCoords[2].set(entireCoords.uvCoords[2].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
        innerCoords2.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
      } else if(direction == 2) {
        innerCoords2.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords2.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords2.uvCoords[2].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[2].y);
        innerCoords2.uvCoords[3].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[3].y);
        
        innerCoords1.uvCoords[0].set((entireCoords.uvCoords[3].x - entireCoords.uvCoords[0].x)/2, entireCoords.uvCoords[0].y);
        innerCoords1.uvCoords[1].set((entireCoords.uvCoords[2].x - entireCoords.uvCoords[1].x)/2, entireCoords.uvCoords[1].y);
        innerCoords1.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords1.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
      } else {
        innerCoords1.uvCoords[0].set(entireCoords.uvCoords[0].x, entireCoords.uvCoords[0].y);
        innerCoords1.uvCoords[1].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords1.uvCoords[2].set(entireCoords.uvCoords[2].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
        innerCoords1.uvCoords[3].set(entireCoords.uvCoords[3].x, entireCoords.uvCoords[3].y);
        
        innerCoords2.uvCoords[0].set(entireCoords.uvCoords[1].x, (entireCoords.uvCoords[1].y - entireCoords.uvCoords[0].y) / 2);
        innerCoords2.uvCoords[1].set(entireCoords.uvCoords[1].x, entireCoords.uvCoords[1].y);
        innerCoords2.uvCoords[2].set(entireCoords.uvCoords[2].x, entireCoords.uvCoords[2].y);
        innerCoords2.uvCoords[3].set(entireCoords.uvCoords[3].x, (entireCoords.uvCoords[2].y - entireCoords.uvCoords[3].y) / 2);
      }
  }
}
