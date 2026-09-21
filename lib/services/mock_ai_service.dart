import 'dart:async';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/models/paper.dart';

class AiStreamEvent {
  final String textChunk;
  final List<Citation>? citations;
  final bool isDone;
  
  const AiStreamEvent({
    required this.textChunk,
    this.citations,
    this.isDone = false,
  });
}

abstract class AiService {
  Stream<AiStreamEvent> askQuestion({
    required String paperId,
    required String question,
    String? selectedText,
    required List<PaperPage> pages,
  });
}

class MockResponse {
  final String fullText;
  final List<Citation> citations;
  
  const MockResponse({
    required this.fullText,
    required this.citations,
  });
}

class MockAiService implements AiService {
  final Map<String, List<Map<String, dynamic>>> _responses = {
    'attention': [
      {
        'keywords': ['attention', 'mechanism', 'multi-head'],
        'response': MockResponse(
          fullText: 'The attention mechanism, specifically **Scaled Dot-Product Attention**, calculates the output as a weighted sum of values. The weights are determined by a compatibility function of queries and keys. \n\nInstead of a single attention function, the authors use **Multi-Head Attention**, which linearly projects queries, keys, and values multiple times and applies attention in parallel. This allows the model to jointly attend to information from different representation subspaces.',
          citations: [
            Citation(paperId: 'attention', page: 4, excerpt: 'Attention(Q,K,V) = softmax(QK^T / sqrt(d_k))V', label: '[1]')
          ],
        )
      },
      {
        'keywords': ['transformer', 'architecture', 'encoder'],
        'response': MockResponse(
          fullText: 'The **Transformer** is a novel architecture that relies entirely on attention mechanisms, dispensing with recurrence and convolutions. It follows an encoder-decoder structure. \n\nThe encoder consists of a stack of 6 identical layers, each containing a multi-head self-attention mechanism and a position-wise fully connected feed-forward network. Residual connections and layer normalization are used around each sub-layer.',
          citations: [
            Citation(paperId: 'attention', page: 1, excerpt: 'based solely on attention mechanisms', label: '[1]'),
            Citation(paperId: 'attention', page: 3, excerpt: 'composed of a stack of N=6 identical layers', label: '[2]')
          ],
        )
      }
    ],
    'gan': [
      {
        'keywords': ['adversarial', 'training', 'game'],
        'response': MockResponse(
          fullText: 'Generative Adversarial Networks involve a **two-player minimax game**. The generative model (G) tries to capture the data distribution and produce fake samples, acting like counterfeiters. \n\nThe discriminative model (D) estimates the probability that a sample came from the real training data rather than G, acting like the police. The competition drives both to improve until fake samples are indistinguishable from real ones.',
          citations: [
            Citation(paperId: 'gan', page: 1, excerpt: 'pitted against an adversary', label: '[1]'),
            Citation(paperId: 'gan', page: 2, excerpt: 'min_G max_D V(D,G)', label: '[2]')
          ],
        )
      },
      {
        'keywords': ['generator', 'discriminator', 'objective'],
        'response': MockResponse(
          fullText: 'The **discriminator** D is trained to maximize the probability of assigning the correct label to both real examples and generated samples. \n\nSimultaneously, the **generator** G is trained to minimize log(1 - D(G(z))). However, in practice, to provide stronger gradients early in learning, G is often trained to maximize log D(G(z)) instead.',
          citations: [
            Citation(paperId: 'gan', page: 2, excerpt: 'maximize log D(G(z))', label: '[1]')
          ],
        )
      }
    ],
    'resnet': [
      {
        'keywords': ['skip', 'residual', 'connection', 'block'],
        'response': MockResponse(
          fullText: 'Deep Residual Networks (ResNets) tackle the degradation problem in deep networks using **shortcut connections** or **residual learning**. \n\nInstead of expecting stacked layers to approximate a complete underlying mapping H(x), they are explicitly forced to approximate a residual function F(x) = H(x) - x. The original function becomes F(x) + x, realized by feedforward neural networks with "shortcut connections" that skip one or more layers.',
          citations: [
            Citation(paperId: 'resnet', page: 3, excerpt: 'approximate a residual function F(x) := H(x) - x', label: '[1]')
          ],
        )
      },
      {
        'keywords': ['depth', 'degradation', 'deeper'],
        'response': MockResponse(
          fullText: 'The authors observed a **degradation problem**: as network depth increases, accuracy saturates and then degrades rapidly. This is not caused by overfitting. \n\nWith residual learning, deeper networks perform better. For instance, a 34-layer ResNet outperforms an 18-layer one and exhibits lower training error. They even successfully trained a very deep 152-layer ResNet.',
          citations: [
            Citation(paperId: 'resnet', page: 1, excerpt: 'accuracy gets saturated and then degrades rapidly', label: '[1]'),
            Citation(paperId: 'resnet', page: 4, excerpt: '34-layer ResNet is better than the 18-layer ResNet', label: '[2]')
          ],
        )
      }
    ],
    'bert': [
      {
        'keywords': ['mask', 'mlm', 'masked'],
        'response': MockResponse(
          fullText: 'BERT uses a **Masked Language Model (MLM)** pre-training objective. It randomly masks some percentage of the input tokens (15% in their experiments) and then predicts those masked tokens. \n\nThis allows the model to train a deep bidirectional representation, as opposed to standard language models that can only be trained left-to-right or right-to-left.',
          citations: [
            Citation(paperId: 'bert', page: 4, excerpt: 'mask 15% of all WordPiece tokens', label: '[1]')
          ],
        )
      },
      {
        'keywords': ['fine-tuning', 'downstream', 'pre-training'],
        'response': MockResponse(
          fullText: 'BERT introduces a unified architecture across different tasks, meaning there is minimal difference between the pre-trained architecture and the final downstream architecture. \n\nFor **fine-tuning**, task-specific inputs and outputs are simply plugged into BERT, and all parameters are fine-tuned end-to-end. This approach achieved state-of-the-art results on many tasks like the GLUE benchmark.',
          citations: [
            Citation(paperId: 'bert', page: 5, excerpt: 'fine-tune all the parameters end-to-end', label: '[1]')
          ],
        )
      }
    ],
    'diffusion': [
      {
        'keywords': ['denoising', 'reverse', 'noise'],
        'response': MockResponse(
          fullText: 'A diffusion model is a parameterized Markov chain. The **reverse process** learns to reverse a diffusion process, gradually removing noise from the data. \n\nDuring training, instead of predicting the mean directly, the neural network is parameterized to predict the **added noise**. This training objective is very simple and equates to denoising score matching.',
          citations: [
            Citation(paperId: 'diffusion', page: 3, excerpt: 'predict the added noise epsilon', label: '[1]')
          ],
        )
      },
      {
        'keywords': ['forward', 'process', 'schedule'],
        'response': MockResponse(
          fullText: 'The **forward process** (or diffusion process) is a fixed Markov chain that gradually adds Gaussian noise to the data according to a predefined variance schedule. \n\nBy rewriting the variational bound in terms of Kullback-Leibler divergences, learning the reverse process transitions amounts to matching the intractable true posterior of the forward process.',
          citations: [
            Citation(paperId: 'diffusion', page: 2, excerpt: 'gradually adds Gaussian noise to the data', label: '[1]')
          ],
        )
      }
    ],
    'dqn': [
      {
        'keywords': ['q-learning', 'q-network', 'value'],
        'response': MockResponse(
          fullText: 'The authors present the **Deep Q-Network (DQN)**, which uses a convolutional neural network to parameterize an approximate value function Q(s, a; theta). \n\nThe network is trained using a variant of Q-learning, taking raw pixels as input and outputting a value function that estimates future rewards. It uses the Bellman equation as an iterative update.',
          citations: [
            Citation(paperId: 'dqn', page: 3, excerpt: 'parameterize an approximate value function', label: '[1]')
          ],
        )
      },
      {
        'keywords': ['experience', 'replay', 'memory'],
        'response': MockResponse(
          fullText: 'To handle correlated data and non-stationary distributions, DQN uses **experience replay**. \n\nThe agent\'s experiences are stored in a replay memory. During learning, Q-learning updates are applied to random samples of experience drawn from this pool. This randomizes samples, breaks correlations, and reduces the variance of the updates.',
          citations: [
            Citation(paperId: 'dqn', page: 3, excerpt: 'drawn at random from the pool of stored samples', label: '[1]')
          ],
        )
      }
    ]
  };

  final MockResponse _fallbackResponse = const MockResponse(
    fullText: 'Based on the provided text, I could not find a specific answer to your question. The paper discusses various topics, but the exact details you are asking about might not be explicitly covered or might require inferring beyond the text. Could you rephrase your question or point to a specific section?',
    citations: [],
  );

  @override
  Stream<AiStreamEvent> askQuestion({
    required String paperId,
    required String question,
    String? selectedText,
    required List<PaperPage> pages,
  }) {
    final controller = StreamController<AiStreamEvent>();
    Timer? timer;
    
    controller.onCancel = () {
      timer?.cancel();
    };

    final qLower = question.toLowerCase();
    final paperResponses = _responses[paperId] ?? [];
    
    MockResponse? selectedResponse;
    for (final item in paperResponses) {
      final keywords = item['keywords'] as List<String>;
      if (keywords.any((kw) => qLower.contains(kw))) {
        selectedResponse = item['response'] as MockResponse;
        break;
      }
    }
    
    selectedResponse ??= _fallbackResponse;
    
    final words = selectedResponse.fullText.split(' ');
    int wordIndex = 0;
    
    timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (controller.isClosed) {
        t.cancel();
        return;
      }
      
      final chunkWords = <String>[];
      for (int i = 0; i < 3 && wordIndex < words.length; i++) {
        chunkWords.add(words[wordIndex]);
        wordIndex++;
      }
      
      final chunk = chunkWords.join(' ') + (wordIndex < words.length ? ' ' : '');
      
      if (wordIndex >= words.length) {
        t.cancel();
        controller.add(AiStreamEvent(
          textChunk: chunk,
          citations: selectedResponse!.citations,
          isDone: true,
        ));
        controller.close();
      } else {
        controller.add(AiStreamEvent(
          textChunk: chunk,
          isDone: false,
        ));
      }
    });
    
    return controller.stream;
  }
}
