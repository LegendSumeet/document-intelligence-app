import 'package:flutter/foundation.dart';

/// One step of the document analysis pipeline.
@immutable
class AnalysisStage {
  const AnalysisStage(this.label, this.weight);

  final String label;

  /// Relative share of the overall progress bar. Roughly mirrors how long a
  /// real pipeline would spend on each step.
  final double weight;
}

/// The stages shown while a document is uploaded and indexed.
const List<AnalysisStage> kAnalysisStages = [
  AnalysisStage('Reading document', 0.25),
  AnalysisStage('Understanding content', 0.30),
  AnalysisStage('Finding important information', 0.30),
  AnalysisStage('Preparing insights', 0.15),
];
