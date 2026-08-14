/// Window-width thresholds for responsive layouts, matching Material 3's
/// window size classes (compact <600, medium 600-839, expanded >=840).
///
/// Generic and feature-agnostic — any screen that needs to adapt its layout
/// should read these rather than inventing its own thresholds.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 840;

  static bool isTablet(double width) => width >= tablet && width < desktop;

  static bool isDesktop(double width) => width >= desktop;

  /// Convenience for grid-style layouts: how many columns a width supports.
  static int columnsFor(double width, {int phoneColumns = 2, int wideColumns = 4}) {
    return width >= tablet ? wideColumns : phoneColumns;
  }
}
