
import Foundation
import SwiftUI

// MARK: - Gemini AI Service
class GeminiService: ObservableObject {
    private let contentAPIKey = "AIzaSyAMRfrt-9Y0Jk6cCQZ9VKOWscVW751-izI"
    private let contentBaseURL = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"
    private let imageBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent"
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var activeTasks: Set<String> = []
    
    // MARK: - Fallback Texts
    private let roleAssignmentTexts = [
        "The shadows gather as fate chooses your destiny. Ancient forces stir in the darkness, whispering secrets that will shape the coming battle between light and shadow.",
        "In the depths of night, destiny awakens. The village stands at the crossroads of fate, where each soul will be marked by powers beyond mortal understanding.",
        "The veil between worlds grows thin as ancient magic flows through the village. Each heart beats with the rhythm of destiny, waiting to discover its true nature.",
        "Whispers of power echo through the darkness. The time has come for souls to be tested, for the eternal struggle between order and chaos to begin anew.",
        "Mystical energies swirl around the village as the cosmic balance shifts. Each person will soon learn their role in the grand design of fate.",
        "The ancient spirits stir, their eyes watching from the shadows. Tonight, the village will be divided by forces that have shaped civilizations for millennia.",
        "Darkness descends upon the village as supernatural forces align. The time has come for each soul to embrace their destiny in the eternal war.",
        "The cosmic wheel turns, bringing with it the weight of destiny. Each villager will soon discover their true nature in this battle of shadows and light.",
        "Mystical currents flow through the air as the village prepares for transformation. Ancient powers awaken, ready to claim their chosen champions.",
        "The veil of reality trembles as supernatural forces converge. Tonight, the village will be forever changed by the roles destiny has chosen.",
        "In the silence of the night, ancient magic awakens. The village stands on the threshold of a new era, where each soul will find its purpose.",
        "The cosmic dance begins as mystical energies swirl around the village. Each heart beats with anticipation, waiting to discover their true calling.",
        "Dark forces gather in the shadows, their whispers carrying the weight of destiny. The village will soon be divided by powers beyond comprehension.",
        "The ancient spirits watch from beyond the veil, their eyes filled with wisdom and power. Tonight, the village will be transformed by their will.",
        "Mystical winds blow through the village, carrying with them the seeds of destiny. Each soul will soon bloom into their true nature.",
        "The cosmic balance shifts as supernatural forces align. The village stands at the center of a great transformation that will change everything.",
        "In the depths of the night, ancient powers stir. The village will soon be divided by forces that have shaped the world since time began.",
        "The veil between worlds grows thin as mystical energies converge. Each villager will soon discover their role in the eternal struggle.",
        "Darkness and light dance in the shadows as destiny unfolds. The village will be forever changed by the roles that fate has chosen.",
        "The ancient spirits awaken, their power flowing through the village like a river of stars. Each soul will soon find its place in the cosmic order.",
        "Mystical currents swirl around the village as the supernatural world bleeds into reality. Tonight, the eternal battle will begin anew.",
        "The cosmic wheel turns, bringing with it the weight of destiny. Each villager will soon discover their true nature in this battle of shadows and light.",
        "In the silence of the night, ancient magic awakens. The village stands on the threshold of a new era, where each soul will find its purpose.",
        "The ancient spirits watch from beyond the veil, their eyes filled with wisdom and power. Tonight, the village will be transformed by their will.",
        "Mystical winds blow through the village, carrying with them the seeds of destiny. Each soul will soon bloom into their true nature.",
        "The cosmic balance shifts as supernatural forces align. The village stands at the center of a great transformation that will change everything.",
        "In the depths of the night, ancient powers stir. The village will soon be divided by forces that have shaped the world since time began.",
        "The veil between worlds grows thin as mystical energies converge. Each villager will soon discover their role in the eternal struggle.",
        "Darkness and light dance in the shadows as destiny unfolds. The village will be forever changed by the roles that fate has chosen.",
        "The ancient spirits awaken, their power flowing through the village like a river of stars. Each soul will soon find its place in the cosmic order."
    ]
    
    private let dayNarrationTexts = [
        "The sun rises over the village, casting long shadows across the cobblestone streets. The night's events weigh heavily on everyone's mind as they gather in the town square.",
        "Dawn breaks through the darkness, illuminating the village with an eerie glow. The air is thick with tension as villagers emerge from their homes, each carrying the weight of suspicion.",
        "Morning light filters through the windows as the village awakens to a new day. The events of the previous night have left their mark, and trust hangs in the balance.",
        "The first rays of sunlight pierce through the morning mist, revealing a village forever changed. Whispers of the night's events echo through the streets.",
        "As the sun climbs higher in the sky, the village begins to stir. The weight of the night's secrets presses down on every heart, creating an atmosphere of unease.",
        "The morning air is crisp and clear, but the village feels different somehow. The shadows of the night still linger, casting doubt on every face.",
        "Dawn brings with it the harsh light of truth, illuminating the village in ways that make everyone uncomfortable. The night's events cannot be undone.",
        "The sun rises over a village transformed by the night's events. Each villager carries the burden of knowledge that will shape their decisions today.",
        "Morning light reveals the true nature of the village, stripped of its illusions. The night has changed everything, and there's no going back.",
        "As the sun climbs over the horizon, the village awakens to a new reality. The events of the night have set in motion a chain of events that cannot be stopped.",
        "The dawn breaks over a village forever changed by the night's events. Each person must now face the consequences of their actions and inactions.",
        "Morning light filters through the windows, revealing a village on the edge of chaos. The night's secrets weigh heavily on every heart.",
        "The sun rises over the village, casting long shadows that seem to whisper of the night's events. Trust has been shattered, and suspicion reigns supreme.",
        "Dawn brings with it the harsh reality of the night's events. The village will never be the same, and each person must choose their path forward.",
        "As the morning light spreads across the village, the weight of the night's secrets becomes unbearable. Each villager must now face the truth.",
        "The sun climbs higher in the sky, illuminating a village forever changed by the night's events. The shadows of doubt and fear linger in every corner.",
        "Morning breaks over a village transformed by the night's events. Each person carries the burden of knowledge that will shape their destiny.",
        "The dawn light reveals the true nature of the village, stripped of its illusions. The night has changed everything, and there's no going back.",
        "As the sun rises over the horizon, the village awakens to a new reality. The events of the night have set in motion a chain of events that cannot be stopped.",
        "The morning air is thick with tension as the village begins to stir. The night's events have left their mark, and trust hangs in the balance.",
        "Dawn breaks through the darkness, illuminating the village with an eerie glow. The air is thick with tension as villagers emerge from their homes.",
        "The first rays of sunlight pierce through the morning mist, revealing a village forever changed. Whispers of the night's events echo through the streets.",
        "As the sun climbs higher in the sky, the village begins to stir. The weight of the night's secrets presses down on every heart.",
        "The morning air is crisp and clear, but the village feels different somehow. The shadows of the night still linger, casting doubt on every face.",
        "Dawn brings with it the harsh light of truth, illuminating the village in ways that make everyone uncomfortable. The night's events cannot be undone.",
        "The sun rises over a village transformed by the night's events. Each villager carries the burden of knowledge that will shape their decisions today.",
        "Morning light reveals the true nature of the village, stripped of its illusions. The night has changed everything, and there's no going back.",
        "As the sun climbs over the horizon, the village awakens to a new reality. The events of the night have set in motion a chain of events that cannot be stopped.",
        "The dawn breaks over a village forever changed by the night's events. Each person must now face the consequences of their actions and inactions.",
        "Morning light filters through the windows, revealing a village on the edge of chaos. The night's secrets weigh heavily on every heart."
    ]
    
    private let discussionPromptTexts = [
        "The village square buzzes with whispered conversations. Everyone has theories about who might be responsible for the night's events. What do you think happened?",
        "Suspicion hangs heavy in the air as villagers gather to discuss the night's events. Each person has their own theory about what really happened.",
        "The morning light reveals a village divided by fear and suspicion. Everyone has something to say about the night's events, but who can be trusted?",
        "As the village awakens to a new day, the weight of the night's secrets presses down on everyone. What do you think really happened?",
        "The town square is alive with whispered conversations and pointed fingers. Everyone has their own theory about who might be responsible.",
        "Suspicion runs deep in the village as people gather to discuss the night's events. Each person carries their own burden of knowledge.",
        "The morning air is thick with tension as villagers try to piece together what happened during the night. What do you think is the truth?",
        "As the sun rises over the village, the weight of the night's events becomes unbearable. Everyone has something to say, but who can be trusted?",
        "The village square is filled with whispered conversations and suspicious glances. Everyone has their own theory about what really happened.",
        "Suspicion hangs heavy in the air as the village tries to make sense of the night's events. What do you think is the truth?",
        "The morning light reveals a village forever changed by the night's events. Everyone has their own theory about who might be responsible.",
        "As the village awakens to a new day, the weight of the night's secrets presses down on everyone. What do you think really happened?",
        "The town square is alive with whispered conversations and pointed fingers. Everyone has their own theory about who might be responsible.",
        "Suspicion runs deep in the village as people gather to discuss the night's events. Each person carries their own burden of knowledge.",
        "The morning air is thick with tension as villagers try to piece together what happened during the night. What do you think is the truth?",
        "As the sun rises over the village, the weight of the night's events becomes unbearable. Everyone has something to say, but who can be trusted?",
        "The village square is filled with whispered conversations and suspicious glances. Everyone has their own theory about what really happened.",
        "Suspicion hangs heavy in the air as the village tries to make sense of the night's events. What do you think is the truth?",
        "The morning light reveals a village forever changed by the night's events. Everyone has their own theory about who might be responsible.",
        "As the village awakens to a new day, the weight of the night's secrets presses down on everyone. What do you think really happened?",
        "The town square is alive with whispered conversations and pointed fingers. Everyone has their own theory about who might be responsible.",
        "Suspicion runs deep in the village as people gather to discuss the night's events. Each person carries their own burden of knowledge.",
        "The morning air is thick with tension as villagers try to piece together what happened during the night. What do you think is the truth?",
        "As the sun rises over the village, the weight of the night's events becomes unbearable. Everyone has something to say, but who can be trusted?",
        "The village square is filled with whispered conversations and suspicious glances. Everyone has their own theory about what really happened.",
        "Suspicion hangs heavy in the air as the village tries to make sense of the night's events. What do you think is the truth?",
        "The morning light reveals a village forever changed by the night's events. Everyone has their own theory about who might be responsible.",
        "As the village awakens to a new day, the weight of the night's secrets presses down on everyone. What do you think really happened?",
        "The town square is alive with whispered conversations and pointed fingers. Everyone has their own theory about who might be responsible.",
        "Suspicion runs deep in the village as people gather to discuss the night's events. Each person carries their own burden of knowledge."
    ]
    
    private let nightNarrationTexts = [
        "As darkness falls over the village, the moon casts eerie shadows through the windows. The air is thick with tension as each player prepares for the night's events. Who will act, and who will be acted upon?",
        "The night envelops the village in a shroud of mystery. Ancient forces stir in the darkness, their whispers carried on the wind. The time for secrets has come.",
        "Beneath the starless sky, the village sleeps uneasily. But not all are at rest - some move through the shadows with purpose, their intentions hidden from the light.",
        "The darkness brings with it the weight of destiny. Each soul must choose their path through the night, knowing that their actions will shape the coming dawn.",
        "As the sun sets and shadows lengthen, the village transforms. What was once familiar becomes strange, and the line between friend and foe blurs in the moonlight.",
        "The night holds its breath as supernatural forces align. Ancient powers awaken, ready to claim their chosen champions in the eternal struggle between light and shadow.",
        "In the depths of the night, the village becomes a stage for a cosmic drama. Each player holds a role in the grand design, their fate intertwined with the others.",
        "The darkness descends like a velvet curtain, hiding the true nature of the village. Beneath the surface, ancient magic flows, shaping destinies in ways no one can predict.",
        "As the stars emerge from the twilight, the village prepares for transformation. The night will test each soul, revealing their true nature in the crucible of darkness.",
        "The moon rises over a village forever changed by the day's events. The shadows hold secrets that will determine the fate of all who dwell within its borders.",
        "In the silence of the night, ancient spirits stir. The village stands at the crossroads of destiny, where each choice echoes through eternity.",
        "The darkness brings with it the promise of revelation. As the night unfolds, the true nature of the village will be revealed, and no one will be the same.",
        "Beneath the starry sky, the village sleeps fitfully. But in the shadows, forces beyond mortal understanding move with purpose, their eyes fixed on the coming dawn.",
        "The night wind carries whispers of power and danger. Each soul must navigate the darkness, knowing that their choices will echo through the ages.",
        "As the sun disappears below the horizon, the village transforms. The familiar becomes strange, and the ordinary becomes extraordinary in the light of the moon.",
        "The darkness holds the village in its embrace, but not all who walk in shadows are enemies. Some seek to protect, while others seek to destroy.",
        "In the depths of the night, the village becomes a battleground for forces beyond comprehension. Each player must choose their side in the eternal struggle.",
        "The moon casts its silver light over a village divided by secrets. As the night unfolds, the truth will be revealed, and the price of knowledge will be paid.",
        "As darkness falls, the village prepares for the ultimate test. The night will separate the strong from the weak, the wise from the foolish, the just from the unjust.",
        "The night holds the village in its thrall, but not all who walk in darkness are lost. Some seek to guide, while others seek to mislead.",
        "Beneath the starless sky, the village sleeps uneasily. But not all are at rest - some move through the shadows with purpose, their intentions hidden from the light.",
        "The darkness brings with it the weight of destiny. Each soul must choose their path through the night, knowing that their actions will shape the coming dawn.",
        "As the sun sets and shadows lengthen, the village transforms. What was once familiar becomes strange, and the line between friend and foe blurs in the moonlight.",
        "The night holds its breath as supernatural forces align. Ancient powers awaken, ready to claim their chosen champions in the eternal struggle between light and shadow.",
        "In the depths of the night, the village becomes a stage for a cosmic drama. Each player holds a role in the grand design, their fate intertwined with the others.",
        "The darkness descends like a velvet curtain, hiding the true nature of the village. Beneath the surface, ancient magic flows, shaping destinies in ways no one can predict.",
        "As the stars emerge from the twilight, the village prepares for transformation. The night will test each soul, revealing their true nature in the crucible of darkness.",
        "The moon rises over a village forever changed by the day's events. The shadows hold secrets that will determine the fate of all who dwell within its borders.",
        "In the silence of the night, ancient spirits stir. The village stands at the crossroads of destiny, where each choice echoes through eternity.",
        "The darkness brings with it the promise of revelation. As the night unfolds, the true nature of the village will be revealed, and no one will be the same."
    ]
    
    private let votingResultsTexts = [
        "The votes have been cast and the tension is palpable. The village waits with bated breath as the final count is revealed. Justice will be served, but at what cost?",
        "As the ballots are counted, the weight of the decision hangs heavy in the air. Each vote represents a choice, a moment of judgment that will change everything.",
        "The moment of truth has arrived. The village stands united in their decision, but the consequences of their choice will echo through the coming days.",
        "The votes are in, and the fate of the accused is sealed. The village has spoken, but will their judgment prove to be wise or foolish?",
        "As the final tally is revealed, the tension breaks like a wave. The village has made its choice, and now they must live with the consequences.",
        "The ballots tell a story of suspicion and fear, of trust broken and alliances shattered. The village has chosen their path, but where will it lead?",
        "The votes have been counted, and the verdict is clear. The village has spoken with one voice, but will their choice bring peace or more conflict?",
        "As the final count is announced, the air is thick with anticipation. The village has made their decision, but the true test is yet to come.",
        "The ballots reveal the depth of the village's fear and suspicion. Each vote represents a moment of doubt, a question that may never be answered.",
        "The votes have been cast, and the die is thrown. The village has chosen their champion, but will their choice prove to be their salvation or their doom?",
        "As the tally is completed, the village holds its breath. The moment of judgment has arrived, and there is no turning back.",
        "The votes tell a tale of trust and betrayal, of hope and despair. The village has spoken, but their words may yet come back to haunt them.",
        "The final count reveals the village's true nature. In their moment of crisis, they have chosen their path, but will it lead to victory or defeat?",
        "As the ballots are revealed, the tension reaches its peak. The village has made their choice, and now they must face the consequences of their decision.",
        "The votes have been counted, and the verdict is in. The village has spoken with one voice, but will their choice bring the peace they seek?",
        "The ballots tell a story of courage and cowardice, of wisdom and folly. The village has chosen their champion, but will their choice prove to be wise?",
        "As the final tally is announced, the village stands at a crossroads. Their decision will shape the future, but will it be for better or for worse?",
        "The votes reveal the depth of the village's desperation. In their moment of need, they have chosen their path, but will it lead to salvation?",
        "The ballots have been cast, and the moment of truth has arrived. The village has spoken, but their words may yet prove to be their undoing.",
        "As the count is completed, the village holds its breath. The moment of judgment has arrived, and there is no turning back from their choice.",
        "The votes tell a tale of unity and division, of strength and weakness. The village has chosen their path, but will it lead to victory or defeat?",
        "The final tally reveals the village's true character. In their moment of crisis, they have made their choice, but will it prove to be the right one?",
        "As the ballots are revealed, the tension reaches its peak. The village has spoken with one voice, but will their choice bring the peace they need?",
        "The votes have been counted, and the verdict is clear. The village has chosen their champion, but will their choice prove to be their salvation?",
        "The ballots tell a story of hope and despair, of trust and betrayal. The village has made their decision, but will it lead to the outcome they desire?",
        "As the final count is announced, the village stands united in their choice. Their decision will shape the future, but will it be for better or for worse?",
        "The votes reveal the depth of the village's determination. In their moment of need, they have chosen their path, but will it lead to success?",
        "The ballots have been cast, and the moment of truth has arrived. The village has spoken, but their words may yet determine their fate.",
        "As the count is completed, the village holds its breath. The moment of judgment has arrived, and their choice will echo through the ages.",
        "The votes tell a tale of courage and fear, of wisdom and doubt. The village has chosen their path, but will it lead to the victory they seek?"
    ]
    
    private func getGameEndNarrationTexts(winner: String) -> [String] {
        return [
            "The final battle is over. The \(winner) have emerged victorious, their strategy and cunning proving superior. The village will remember this day, and the lessons learned will echo through the ages.",
            "As the dust settles, the \(winner) stand triumphant. Their victory was hard-won, but their determination and skill have carried the day. The village will never forget this moment.",
            "The struggle has ended, and the \(winner) have proven their worth. Their victory is a testament to their courage and wisdom, and the village will honor their memory forever.",
            "The final confrontation is over, and the \(winner) have emerged as the true champions. Their victory will be remembered as a turning point in the village's history.",
            "As the conflict reaches its conclusion, the \(winner) stand victorious. Their triumph is a beacon of hope in a world of darkness, and the village will never forget their sacrifice.",
            "The battle is won, and the \(winner) have proven themselves worthy of victory. Their success will inspire future generations to stand against the forces of evil.",
            "The final chapter has been written, and the \(winner) have emerged as the heroes of this tale. Their victory will be celebrated for generations to come.",
            "As the smoke clears, the \(winner) stand as the undisputed champions. Their victory is a testament to their strength and determination, and the village will forever be grateful.",
            "The struggle has ended, and the \(winner) have proven their mettle. Their victory will be remembered as one of the greatest triumphs in the village's long history.",
            "The final battle is over, and the \(winner) have emerged victorious. Their success will be celebrated as a victory for all that is good and just in the world.",
            "As the conflict reaches its climax, the \(winner) stand triumphant. Their victory is a shining example of what can be achieved through courage and determination.",
            "The battle is won, and the \(winner) have proven themselves to be true champions. Their victory will inspire others to stand up for what is right.",
            "The final confrontation is over, and the \(winner) have emerged as the victors. Their success will be remembered as a defining moment in the village's history.",
            "As the dust settles, the \(winner) stand as the undisputed winners. Their victory is a testament to their skill and determination, and the village will never forget their achievement.",
            "The struggle has ended, and the \(winner) have proven their worth. Their victory will be celebrated as a triumph of good over evil, and their legacy will live on forever.",
            "The final chapter has been written, and the \(winner) have emerged as the heroes of this story. Their victory will be remembered as one of the greatest achievements in the village's history.",
            "As the smoke clears, the \(winner) stand victorious. Their triumph is a beacon of hope in a world of darkness, and the village will never forget their sacrifice.",
            "The battle is won, and the \(winner) have proven themselves to be true champions. Their victory will inspire future generations to stand against the forces of evil.",
            "The final confrontation is over, and the \(winner) have emerged as the victors. Their success will be celebrated as a victory for all that is good and just in the world.",
            "As the conflict reaches its conclusion, the \(winner) stand triumphant. Their victory is a shining example of what can be achieved through courage and determination.",
            "The struggle has ended, and the \(winner) have proven their mettle. Their victory will be remembered as one of the greatest triumphs in the village's long history.",
            "The final battle is over, and the \(winner) have emerged victorious. Their success will be celebrated as a triumph of good over evil, and their legacy will live on forever.",
            "As the dust settles, the \(winner) stand as the undisputed champions. Their victory is a testament to their strength and determination, and the village will forever be grateful.",
            "The battle is won, and the \(winner) have proven themselves worthy of victory. Their success will inspire others to stand up for what is right.",
            "The final chapter has been written, and the \(winner) have emerged as the heroes of this tale. Their victory will be celebrated for generations to come.",
            "As the smoke clears, the \(winner) stand victorious. Their triumph is a beacon of hope in a world of darkness, and the village will never forget their sacrifice.",
            "The struggle has ended, and the \(winner) have proven their worth. Their victory will be remembered as a defining moment in the village's history.",
            "The final confrontation is over, and the \(winner) have emerged as the victors. Their success will be celebrated as a victory for all that is good and just in the world.",
            "As the conflict reaches its climax, the \(winner) stand triumphant. Their victory is a shining example of what can be achieved through courage and determination.",
            "The battle is won, and the \(winner) have proven themselves to be true champions. Their victory will inspire future generations to stand against the forces of evil."
        ]
    }
    
    // MARK: - Content Generation
    func generateRoleAssignment(for players: [Player]) async -> String {
        let taskId = "roleAssignment_\(players.count)"
        
        // Prevent duplicate requests
        if activeTasks.contains(taskId) {
            return getRandomRoleAssignmentText()
        }
        
        activeTasks.insert(taskId)
        defer { activeTasks.remove(taskId) }
        
        let prompt = """
        You are the Game Master for a Mafia game. Create a dramatic, mysterious narrative for role assignment.
        
        This is the moment when roles are about to be distributed to the players. Create an atmospheric story that builds tension and anticipation.
        Make it sound like a dark, mysterious tale about fate choosing destinies.
        Do NOT mention specific roles, players, or names - keep it completely general and atmospheric.
        Focus on the mystery, shadows, and the weight of destiny.
        
        Keep it under 80 words. Start with "The shadows gather as fate chooses your destiny..." and create a brief narrative.
        """
        
        return await makeContentRequestWithTimeout(prompt: prompt, fallback: getRandomRoleAssignmentText())
    }
    
    func generateNightNarration(for phase: GamePhase, players: [Player]) async -> String {
        let taskId = "nightNarration_\(players.count)"
        
        // Prevent duplicate requests
        if activeTasks.contains(taskId) {
            return getRandomNightNarrationText()
        }
        
        activeTasks.insert(taskId)
        defer { activeTasks.remove(taskId) }
        
        let alivePlayers = players.filter { $0.isAlive }
        let playerNames = alivePlayers.map { $0.name }.joined(separator: ", ")
        
        let prompt = """
        You are the Game Master for a Mafia game. It's night time and these players are still alive: \(playerNames)
        
        Create a dark, atmospheric night narration. Describe the moonlit shadows, the tension in the air, 
        and the sense of danger. Make it mysterious and foreboding. Keep it under 100 words.
        
        Start with "As darkness falls over the village..."
        """
        
        return await makeContentRequestWithTimeout(prompt: prompt, fallback: getRandomNightNarrationText())
    }
    
    func generateDayNarration(for phase: GamePhase, players: [Player], eliminatedPlayer: Player?) async -> String {
        let taskId = "dayNarration_\(players.count)_\(eliminatedPlayer?.name ?? "none")"
        
        // Prevent duplicate requests
        if activeTasks.contains(taskId) {
            return getRandomDayNarrationText()
        }
        
        activeTasks.insert(taskId)
        defer { activeTasks.remove(taskId) }
        
        let alivePlayers = players.filter { $0.isAlive }
        let playerNames = alivePlayers.map { $0.name }.joined(separator: ", ")
        
        var prompt = """
        You are the Game Master for a Mafia game. It's day time and these players are still alive: \(playerNames)
        """
        
        if let eliminated = eliminatedPlayer {
            prompt += "\n\nLast night, \(eliminated.name) was eliminated. Create a dramatic narration about the discovery and the village's reaction."
        } else {
            prompt += "\n\nNo one was eliminated last night. Create a narration about the peaceful night and the village's relief."
        }
        
        prompt += "\n\nMake it atmospheric and engaging. Keep it under 100 words. Start with 'As dawn breaks over the village...'"
        
        return await makeContentRequestWithTimeout(prompt: prompt, fallback: getRandomDayNarrationText())
    }
    
    func generateDiscussionPrompt(for players: [Player]) async -> String {
        let taskId = "discussionPrompt_\(players.count)"
        
        // Prevent duplicate requests
        if activeTasks.contains(taskId) {
            return getRandomDiscussionPromptText()
        }
        
        activeTasks.insert(taskId)
        defer { activeTasks.remove(taskId) }
        
        let alivePlayers = players.filter { $0.isAlive }
        let playerNames = alivePlayers.map { $0.name }.joined(separator: ", ")
        
        let prompt = """
        You are the Game Master for a Mafia game. These players are alive and need to discuss: \(playerNames)
        
        Create a thought-provoking discussion prompt that encourages players to analyze, debate, and share information.
        Make it mysterious and engaging. Suggest what they should look for or discuss.
        
        Keep it under 80 words. Start with "The village must decide..."
        """
        
        return await makeContentRequestWithTimeout(prompt: prompt, fallback: getRandomDiscussionPromptText())
    }
    
    func generateVotingResults(for votes: [String: Int], players: [Player]) async -> String {
        let taskId = "votingResults_\(votes.count)"
        
        // Prevent duplicate requests
        if activeTasks.contains(taskId) {
            return getRandomVotingResultsText()
        }
        
        activeTasks.insert(taskId)
        defer { activeTasks.remove(taskId) }
        
        let prompt = """
        You are the Game Master for a Mafia game. The votes have been cast and counted.
        
        Create a dramatic narration about the voting process and the tension as the results are revealed.
        Make it suspenseful and engaging. Keep it under 100 words.
        
        Start with "The votes have been cast..."
        """
        
        return await makeContentRequestWithTimeout(prompt: prompt, fallback: getRandomVotingResultsText())
    }
    
    func generateGameEndNarration(winner: String, players: [Player]) async -> String {
        let taskId = "gameEndNarration_\(winner)_\(players.count)"
        
        // Prevent duplicate requests
        if activeTasks.contains(taskId) {
            return getRandomGameEndNarrationText(winner: winner)
        }
        
        activeTasks.insert(taskId)
        defer { activeTasks.remove(taskId) }
        
        let prompt = """
        You are the Game Master for a Mafia game. The \(winner) have won!
        
        Create a dramatic conclusion to the game. Make it epic and satisfying.
        Reference the final outcome and the players' journey. Keep it under 120 words.
        
        Start with "The final battle is over..."
        """
        
        return await makeContentRequestWithTimeout(prompt: prompt, fallback: getRandomGameEndNarrationText(winner: winner))
    }
    
    // MARK: - Private Methods
    private func makeContentRequest(prompt: String) async -> String? {
        guard let url = URL(string: "\(contentBaseURL)?key=\(contentAPIKey)") else {
            lastError = "Invalid URL"
            return nil
        }
        
        let requestBody = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        let systemInfo = getSystemInfo()
        request.setValue("Xolcaryth-Ember-Spires/1.0 (\(systemInfo))", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            await MainActor.run {
                lastError = "Failed to encode request: \(error.localizedDescription)"
            }
            return nil
        }
        
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            // Configure URLSession for better compatibility with iOS 26
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30.0
            config.timeoutIntervalForResource = 60.0
            let systemInfo = getSystemInfo()
            config.httpAdditionalHeaders = [
                "User-Agent": "Xolcaryth-Ember-Spires/1.0 (\(systemInfo))",
                "Accept": "application/json",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": "keep-alive"
            ]
            
            let session = URLSession(configuration: config)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    lastError = "Invalid HTTP response"
                }
                return nil
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = "HTTP request failed with status: \(httpResponse.statusCode)"
                print("Gemini API Error: \(errorMessage)")
                if let responseData = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseData)")
                }
                await MainActor.run {
                    lastError = errorMessage
                }
                return nil
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Gemini API Response: \(json)")
                
                if let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    await MainActor.run {
                        isLoading = false
                    }
                    return text
                } else {
                    print("Failed to parse Gemini response structure")
                    await MainActor.run {
                        lastError = "Invalid response format from Gemini API"
                    }
                }
            } else {
                print("Failed to parse JSON response")
                await MainActor.run {
                    lastError = "Invalid JSON response from Gemini API"
                }
            }
        } catch {
            await MainActor.run {
                lastError = "Request failed: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
        return nil
    }
    
    // MARK: - Fallback Content
    private func generateFallbackRoleAssignment() -> String {
        return "The shadows gather as fate chooses your destiny... Each soul is bound to a role that will determine their path through the coming trials. Trust no one, for the night holds many secrets."
    }
    
    private func generateFallbackNightNarration() -> String {
        return "As darkness falls over the village, the moon casts eerie shadows through the windows. The air is thick with tension as each player prepares for the night's events. Who will act, and who will be acted upon?"
    }
    
    private func generateFallbackDayNarration(eliminatedPlayer: Player?) -> String {
        if let eliminated = eliminatedPlayer {
            return "As dawn breaks over the village, the grim discovery is made. \(eliminated.name) lies still, their fate sealed by the night's events. The remaining villagers gather, fear and suspicion in their eyes."
        } else {
            return "As dawn breaks over the village, the night has passed peacefully. All players remain safe, but the tension lingers. The villagers gather, wondering what the day will bring."
        }
    }
    
    private func generateFallbackDiscussionPrompt() -> String {
        return "The village must decide who among them poses the greatest threat. Look for inconsistencies in stories, unusual behavior, or those who seem to know too much. Trust your instincts, but beware of false accusations."
    }
    
    private func generateFallbackVotingResults() -> String {
        return "The votes have been cast and the tension is palpable. The village waits with bated breath as the final count is revealed. Justice will be served, but at what cost?"
    }
    
    private func generateFallbackGameEndNarration(winner: String) -> String {
        return "The final battle is over. The \(winner) have emerged victorious, their strategy and cunning proving superior. The village will remember this day, and the lessons learned will echo through the ages."
    }
    
    // MARK: - Random Text Selection
    private func getRandomRoleAssignmentText() -> String {
        return roleAssignmentTexts.randomElement() ?? generateFallbackRoleAssignment()
    }
    
    private func getRandomDayNarrationText() -> String {
        return dayNarrationTexts.randomElement() ?? generateFallbackDayNarration(eliminatedPlayer: nil)
    }
    
    private func getRandomDiscussionPromptText() -> String {
        return discussionPromptTexts.randomElement() ?? generateFallbackDiscussionPrompt()
    }
    
    private func getRandomNightNarrationText() -> String {
        return nightNarrationTexts.randomElement() ?? generateFallbackNightNarration()
    }
    
    private func getRandomVotingResultsText() -> String {
        return votingResultsTexts.randomElement() ?? generateFallbackVotingResults()
    }
    
    private func getRandomGameEndNarrationText(winner: String) -> String {
        let texts = getGameEndNarrationTexts(winner: winner)
        return texts.randomElement() ?? generateFallbackGameEndNarration(winner: winner)
    }
    
    // MARK: - API Testing
    func testAPIConnection() async -> Bool {
        let testPrompt = "Hello, this is a test message. Please respond with 'API connection successful'."
        
        guard let result = await makeContentRequest(prompt: testPrompt) else {
            print("API test failed: No response received")
            return false
        }
        
        print("API test response: \(result)")
        return !result.isEmpty
    }
    
    func getSystemInfo() -> String {
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        
        return "iOS \(systemVersion), \(deviceModel), App Version: \(appVersion)"
    }
    
    // MARK: - Timeout Request
    private func makeContentRequestWithTimeout(prompt: String, fallback: String) async -> String {
        return await withTaskGroup(of: String.self) { group in
            // Start the actual API request
            group.addTask {
                await self.makeContentRequest(prompt: prompt) ?? fallback
            }
            
            // Start the timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
                return fallback
            }
            
            // Return the first completed task
            return await group.first { _ in true } ?? fallback
        }
    }
    }

