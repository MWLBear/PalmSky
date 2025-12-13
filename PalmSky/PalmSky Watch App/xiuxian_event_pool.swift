import Foundation

// MARK: - Event Pool
class EventPool {
    static let shared = EventPool()
    private init() {}
    
    private let events: [GameEvent] = [
        // 奇遇1: 山间灵泉
        GameEvent(
            id: "evt_001",
            title: "山间灵泉",
            desc: "泉眼冒出淡淡灵气，是否取一瓢？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "取来一瓢",
                    effect: EventEffect(type: .gainQi, value: 120)
                ),
                EventChoice(
                    id: "b",
                    text: "绕行而过",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "common"
        ),
        
        // 奇遇2: 道友相赠
        GameEvent(
            id: "evt_002",
            title: "道友相赠",
            desc: "一位道友欲赠你丹药，是否接受？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "欣然接受",
                    effect: EventEffect(type: .gainQi, value: 200)
                ),
                EventChoice(
                    id: "b",
                    text: "婉拒好意",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "common"
        ),
        
        // 奇遇3: 妖兽袭击
        GameEvent(
            id: "evt_003",
            title: "妖兽袭击",
            desc: "突遇妖兽，战或是逃？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "奋力迎战",
                    effect: EventEffect(type: .loseQi, value: 100)
                ),
                EventChoice(
                    id: "b",
                    text: "迅速逃离",
                    effect: EventEffect(type: .loseQi, value: 50)
                )
            ],
            rarity: "common"
        ),
        
        // 奇遇4: 古洞府
        GameEvent(
            id: "evt_004",
            title: "古洞府",
            desc: "发现一处古洞府，是否探索？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "进入探索",
                    effect: EventEffect(type: .gainQi, value: 300)
                ),
                EventChoice(
                    id: "b",
                    text: "谨慎离开",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "rare"
        ),
        
        // 奇遇5: 灵草采集
        GameEvent(
            id: "evt_005",
            title: "灵草采集",
            desc: "路遇珍稀灵草，要采摘吗？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "小心采摘",
                    effect: EventEffect(type: .gainQi, value: 150)
                ),
                EventChoice(
                    id: "b",
                    text: "留给他人",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "common"
        ),
        
        // 奇遇6: 天降异象
        GameEvent(
            id: "evt_006",
            title: "天降异象",
            desc: "天空出现异象，感应到机缘",
            choices: [
                EventChoice(
                    id: "a",
                    text: "静心感悟",
                    effect: EventEffect(type: .gainQi, value: 250)
                ),
                EventChoice(
                    id: "b",
                    text: "继续修炼",
                    effect: EventEffect(type: .gainQi, value: 100)
                )
            ],
            rarity: "rare"
        ),
        
        // 奇遇7: 魔族挑衅
        GameEvent(
            id: "evt_007",
            title: "魔族挑衅",
            desc: "魔族来犯，如何应对？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "正面迎敌",
                    effect: EventEffect(type: .loseQi, value: 150)
                ),
                EventChoice(
                    id: "b",
                    text: "智取制敌",
                    effect: EventEffect(type: .loseQi, value: 80)
                )
            ],
            rarity: "common"
        ),
        
        // 奇遇8: 仙人指点
        GameEvent(
            id: "evt_008",
            title: "仙人指点",
            desc: "得遇前辈仙人，传授心法",
            choices: [
                EventChoice(
                    id: "a",
                    text: "虚心请教",
                    effect: EventEffect(type: .gainQi, value: 400)
                ),
                EventChoice(
                    id: "b",
                    text: "独自领悟",
                    effect: EventEffect(type: .gainQi, value: 150)
                )
            ],
            rarity: "rare"
        ),
        
        // 奇遇9: 灵石矿脉
        GameEvent(
            id: "evt_009",
            title: "灵石矿脉",
            desc: "发现灵石矿脉，是否开采？",
            choices: [
                EventChoice(
                    id: "a",
                    text: "开采灵石",
                    effect: EventEffect(type: .gainQi, value: 180)
                ),
                EventChoice(
                    id: "b",
                    text: "留待日后",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "common"
        ),
        
        // 奇遇10: 护身符
        GameEvent(
            id: "evt_010",
            title: "神秘商人",
            desc: "神秘商人出售护身符一枚",
            choices: [
                EventChoice(
                    id: "a",
                    text: "购买护符",
                    effect: EventEffect(type: .grantItem, value: nil)
                ),
                EventChoice(
                    id: "b",
                    text: "婉拒商人",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "rare"
        ),
        
        // 奇遇11: 雷劫之力
        GameEvent(
            id: "evt_011",
            title: "雷劫之力",
            desc: "天降雷霆，可吸纳淬体",
            choices: [
                EventChoice(
                    id: "a",
                    text: "引雷淬体",
                    effect: EventEffect(type: .gainQi, value: 350)
                ),
                EventChoice(
                    id: "b",
                    text: "躲避雷劫",
                    effect: EventEffect(type: .nothing, value: nil)
                )
            ],
            rarity: "rare"
        ),
        
        // 奇遇12: 心魔考验
        GameEvent(
            id: "evt_012",
            title: "心魔考验",
            desc: "修炼遇到心魔，需克服障碍",
            choices: [
                EventChoice(
                    id: "a",
                    text: "正面对抗",
                    effect: EventEffect(type: .loseQi, value: 120)
                ),
                EventChoice(
                    id: "b",
                    text: "慢慢化解",
                    effect: EventEffect(type: .loseQi, value: 60)
                )
            ],
            rarity: "common"
        )
    ]
    
    func randomEvent() -> GameEvent? {
        return events.randomElement()
    }
    
    func eventById(_ id: String) -> GameEvent? {
        return events.first { $0.id == id }
    }
}
