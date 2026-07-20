import FoundationModels

/// Sample structured output for the Guided tab.
@Generable(description: "A short trip plan")
struct TripPlan {
  @Guide(description: "Destination city")
  var destination: String
  @Guide(description: "Length in days")
  var days: Int
  @Guide(description: "Three highlight activities")
  var highlights: [String]
  @Guide(description: "Rough daily budget in USD")
  var dailyBudgetUSD: Int
}
