# 도토리 베이커리 그림 프롬프트 (2026-10-29)

그림 AI(ChatGPT 이미지, 미드저니, 제미나이 등)에 붙여넣는 프롬프트예요. 영어로 쓰는 게 결과가 더 안정적이라 영어로 적고, 무엇을 그리는지 한국어로 달았어요.

## 쓰기 전에 꼭 지킬 것

- **다른 게임 이름을 넣지 않아요.** "쿠키샵 스타일", "스타듀밸리 스타일"처럼 쓰면 저작권 문제가 생길 수 있어요. 원하는 느낌은 아래처럼 말로 설명해요.
- 원작 스크린샷을 참고 이미지로 올리지 않아요.
- **그림체를 맞추는 방법**: 1번 주인공 그림이 마음에 들면, 그다음부터는 그 그림을 참고 이미지로 같이 올리고 "same art style as the reference image"를 붙여요. 모든 프롬프트에 아래 "공통 그림체" 문단을 그대로 넣어요.
- 스팀에 올릴 때 AI 그림을 썼다고 밝혀야 하고, AI만으로 만든 그림은 저작권 보호를 못 받을 수 있어요. 마음에 드는 그림이 나오면 나중에 작가에게 다듬어 달라고 하는 게 안전해요.

## 공통 그림체 (2026-10-29 확정, 모든 프롬프트 앞에 붙이기)

사용자가 제미나이로 만든 주인공 시트([여자](art/hero-female-sheet.png), [남자](art/hero-male-sheet.png))가 게임 전체의 기준 그림체예요. **매번 이 두 장 중 하나를 참고 이미지로 같이 올려요.**

```
Use the attached image as the art style reference and match it exactly. Soft hand-drawn 2D illustration with thin warm-brown outlines, flat soft colors with very light shading, gentle rosy blush on cheeks, warm cream background tones. Palette: cream, butter yellow, dusty strawberry pink, chestnut brown, soft sky blue, warm beige. Natural cute human proportions about 5 heads tall, not chibi. Calm, cozy, wholesome, slightly nostalgic. No text, no logos, no watermark.
```

기준 색 (게임 화면·UI도 이 색으로 맞춰요): 바탕 크림 `#FBF3E3`, 선 `#7A4E3C`, 딸기 분홍 `#E07A86`, 연분홍 `#F2A9B4`, 앞치마 크림 `#F7EDCB`, 머리 밤색 `#8E5A3A`, 피부 `#F8DCC8`, 하늘색 `#A9CFE8`, 바지 갈색 `#8A6648`.

## 게임에 바로 쓰는 그림 (다음 순서로)

게임 속 캐릭터는 화면에서 작게(키 120~160픽셀쯤) 보여요. 아래는 게임에 넣을 수 있게 정리된 그림이에요. 배경은 단색으로 받고, 배경 지우기와 잘라내기는 제가 해요.

**A. 걷기 동작 (방향마다 한 장씩, 여자·남자 각각)**

```
[공통 그림체]
Sprite sheet of the same character as the reference image walking, seen from the front (facing the viewer). 6 frames of a smooth walk cycle in one horizontal row, same size and same baseline in every frame, evenly spaced, full body, plain flat light cream background, no shadows.
```

`seen from the front` 를 `seen from the back`, `seen from the left side`, `seen from the right side` 로 바꿔서 4장 만들어요. 대각선 화면(쿼터뷰)이면 `seen from a 3/4 front angle facing down-left` 처럼 4방향으로 해요.

**B. 가만히 서 있기 + 일하는 동작**

```
[공통 그림체]
Sprite sheet of the same character as the reference image, one row each: idle breathing (4 frames), stirring a mixing bowl (4 frames), carrying a tray of cookies (4 frames), happy jump (4 frames). Same size and baseline in every frame, plain flat light cream background, no shadows.
```

**C. 표정 얼굴 (대화창용)**

```
[공통 그림체]
Portrait sheet of the same character as the reference image, chest-up, 6 expressions in a 3x2 grid: smiling, laughing, surprised, worried, proud, sleepy. Plain flat light cream background.
```

## 아래 1~10번은 처음 만들 때 쓴 프롬프트예요

이제 앞에 붙이는 문단은 위 "공통 그림체(확정)"로 바꿔 쓰고, 참고 이미지를 같이 올려요. 1, 2번 주인공 시트는 이미 완성했어요.

## 1. 주인공 (여자)

정면, 옆, 뒤 모습이 한 장에 나오는 캐릭터 시트예요.

```
[공통 그림체]
Character turnaround sheet of the female main character, a young woman baker in her early 20s. Long wavy chestnut-brown hair, a white bandana with small pink polka dots, big warm brown eyes, light blush. Pink blouse with puffed short sleeves, cream apron with a small pocket, knee-length strawberry-pink skirt, white socks, brown shoes. Front view, side view, back view, standing in a neutral pose, full body, plain light cream background, evenly spaced.
```

## 2. 주인공 (남자)

```
[공통 그림체]
Character turnaround sheet of the male main character, a young man baker in his early 20s. Short messy dark-brown hair, a white bandana with a sky-blue stripe, friendly brown eyes. Sky-blue shirt with rolled-up sleeves, cream apron, brown trousers, brown shoes. Front view, side view, back view, standing in a neutral pose, full body, plain light cream background, evenly spaced.
```

## 3. 주인공 표정과 동작

1, 2번이 마음에 들면 그 그림을 참고 이미지로 올리고 써요.

```
[공통 그림체]
Same character as the reference image, same art style. Expression and pose sheet: happy, surprised, tired, proud holding a cake, walking, carrying a tray, stirring a mixing bowl, swinging a wooden spatula like a sword, casting a small sparkle spell. Full body, plain light cream background.
```

## 4. 가게 홀 (게임 화면)

비스듬히 내려다보는 쿼터뷰 화면이에요.

```
[공통 그림체]
Isometric 3/4 top-down view of a small cozy bakery cafe interior, game screen. Warm wooden floor, pale pink striped wallpaper, a glass display case with cookies and strawberry cakes, a chalkboard menu without readable text, round wooden tables with pink cushioned chairs, a soft rug with a flower pattern, potted plants, a door to the kitchen at the back. A few cute animal customers sitting at tables (a white rabbit, an orange cat, a fawn), and a puppy waiter with a pink hair pin carrying a tray. Bright afternoon light from a window. Empty space at the top and bottom for game UI.
```

## 5. 주방 화면

재료와 도구가 크게 보이고, 맨 아래에 조합 칸이 있는 화면이에요.

```
[공통 그림체]
Game screen of a cozy bakery kitchen seen from the front. Upper area: wooden shelves holding ingredients drawn large and clearly, each in its own slot: flour sack, sugar jar, butter block, eggs in a basket, milk bottle, chocolate bar, a bowl of wild raspberries, whipped cream. Middle row: baking tools and dishes: rolling pin, star cookie cutter, cake tin, piping bag, mixing bowl, cake plate, mug. Bottom: a long wooden tray with five empty square slots in a row for combining ingredients, and a round check button at the right end. A brick oven glowing softly on the right side. No text.
```

## 6. 도토리 숲 마을 (내 동네)

```
[공통 그림체]
Isometric 3/4 top-down view of a small forest village square, game map. In the center a cute bakery building with a red and white striped awning and an acorn-shaped sign without text. Around it: an ingredient shop, a dishware shop, a furniture shop, an interior shop, a clothing shop, cobblestone paths, oak trees with acorns, flower beds, wild raspberry bushes that can be picked. Paths leading out to the north, east, south and west edges. Friendly animal villagers walking (bear, squirrel, dog, cat).
```

## 7. 다른 마을 4곳

같은 그림체로 하나씩 만들어요. 6번 그림을 참고 이미지로 올리면 좋아요.

```
[공통 그림체]
Isometric 3/4 top-down view of a village for the same game, same art style as the reference image.
```

뒤에 하나씩 붙여요.

- 꽃잎 언덕 (북쪽): `Petal Hill village: rolling hills covered in flowers, a windmill, strawberry fields, beehives, an ingredient shop. Rabbit, deer and chick villagers.`
- 조개 바닷가 (동쪽): `Seashell Beach village: sandy beach, a small lighthouse, wooden pier, lemon trees, coconut palms, a seaside ingredient shop and dishware shop. Otter, sea otter and duck villagers.`
- 사과 과수원 (남쪽): `Apple Orchard village: rows of apple and blueberry trees, a red barn, carrot patches, a wooden furniture shop. Pig, hamster and koala villagers.`
- 눈꽃 산마을 (서쪽): `Snowflake Mountain village: snowy cottages with warm windows, pine trees, a cozy ingredient shop with hanging spices. Lion cub and koala villagers in knitted scarves.`

## 8. 몬스터 (귀엽게)

```
[공통 그림체]
Sprite sheet of cute, not scary monsters for a cozy game, each one separate on a plain light background: a spiky chestnut creature, a grumpy acorn, a fluffy bee swarm, a sleepy flower bud, a salt crab, a squishy jellyfish, a snowball fairy, a small ice spirit. Round shapes, big eyes, soft colors.
```

## 9. 음식과 아이콘

```
[공통 그림체]
Game item icon sheet, each item centered in its own square with no background: butter cookie, chocolate chip cookie, star sugar cookie with icing, raspberry jam cookie, honey cookie, lemon cookie, coconut cookie, macaron, milk bread loaf, butter roll, chestnut bread, salt bread, croissant, blueberry muffin, apple pie, honey bread, raspberry cream cake, chocolate cake, strawberry roll cake, cheesecake, carrot cake, snowflake honey cake, hot cocoa, warm milk, flower tea, lemonade. Consistent size and lighting.
```

## 10. 스팀 대표 그림 (나중에)

```
[공통 그림체]
Key art for the game "Acorn Bakery": a young woman and a young man baker standing proudly in front of a cozy forest bakery with a striped awning, surrounded by cute animal friends (a puppy waiter, a rabbit, a cat, a squirrel), holding a strawberry cake and a tray of cookies, warm golden afternoon light, acorn trees around, wide horizontal composition with empty space at the top for the title.
```

## 잘 안 나올 때

- 너무 아기 같으면: `natural human proportions, 5 heads tall, not chibi` 를 앞쪽에 한 번 더.
- 너무 사실적이면: `soft painterly cartoon style, simple shading`.
- 글자가 생기면: `no text, no letters` 를 끝에 한 번 더.
- 그림체가 장마다 다르면: 마음에 든 그림 1장을 참고 이미지로 계속 같이 올려요.
