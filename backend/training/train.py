"""
🧠 OPTIMIZED Brain Tumor Classification
========================================
✓ Lightweight: EfficientNet-B0 (fast training & inference)
✓ High Precision: Focal Loss + Class Weights
✓ High Accuracy: Strong augmentation + proper regularization
✓ MRI-Ready: Grayscale-aware preprocessing
"""

import os
import copy
import time
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, models, transforms
from torch.optim.lr_scheduler import OneCycleLR
from collections import Counter

# =============================================================================
# CONFIGURATION
# =============================================================================
DATA_DIR = r"C:\Users\ksrak\Documents\Brain MRI"
MODEL_SAVE_DIR = os.path.join(os.path.dirname(__file__), "../models")
os.makedirs(MODEL_SAVE_DIR, exist_ok=True)

BATCH_SIZE = 16
NUM_EPOCHS = 15
INPUT_SIZE = 224
LEARNING_RATE = 0.001
EARLY_STOP_PATIENCE = 5
COOLING_PAUSE = 8  # Seconds

# =============================================================================
# FOCAL LOSS (Better precision on hard cases)
# =============================================================================
class FocalLoss(nn.Module):
    def __init__(self, alpha=None, gamma=2.0):
        super().__init__()
        self.alpha = alpha
        self.gamma = gamma
        
    def forward(self, inputs, targets):
        ce_loss = nn.functional.cross_entropy(inputs, targets, weight=self.alpha, reduction='none')
        pt = torch.exp(-ce_loss)
        focal_loss = ((1 - pt) ** self.gamma) * ce_loss
        return focal_loss.mean()

# =============================================================================
# DATA TRANSFORMS (MRI-optimized)
# =============================================================================
def get_data_transforms(input_size):
    return {
        'Training': transforms.Compose([
            transforms.Resize((input_size, input_size)),
            transforms.RandomHorizontalFlip(p=0.5),
            transforms.RandomRotation(15),
            transforms.RandomAffine(degrees=0, translate=(0.05, 0.05)),
            transforms.ColorJitter(brightness=0.1, contrast=0.1),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
        ]),
        'Validation': transforms.Compose([
            transforms.Resize((input_size, input_size)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
        'Testing': transforms.Compose([
            transforms.Resize((input_size, input_size)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ]),
    }

def load_data():
    print("Loading dataset...")
    data_transforms = get_data_transforms(INPUT_SIZE)
    
    image_datasets = {
        x: datasets.ImageFolder(os.path.join(DATA_DIR, x), data_transforms[x])
        for x in ['Training', 'Validation', 'Testing']
    }
    
    dataloaders = {
        x: DataLoader(image_datasets[x], batch_size=BATCH_SIZE, shuffle=(x == 'Training'), num_workers=0)
        for x in ['Training', 'Validation', 'Testing']
    }
    
    dataset_sizes = {x: len(image_datasets[x]) for x in ['Training', 'Validation', 'Testing']}
    class_names = image_datasets['Training'].classes
    
    # Class weights
    train_labels = [label for _, label in image_datasets['Training']]
    class_counts = Counter(train_labels)
    total = sum(class_counts.values())
    class_weights = torch.tensor([total / class_counts[i] for i in range(len(class_names))], dtype=torch.float32)
    class_weights = class_weights / class_weights.sum() * len(class_names)
    
    return dataloaders, dataset_sizes, class_names, class_weights

# =============================================================================
# LIGHTWEIGHT MODEL
# =============================================================================
def create_model(num_classes, device):
    print("Loading EfficientNet-B0 (Lightweight + Accurate)...")
    model = models.efficientnet_b0(weights='IMAGENET1K_V1')
    
    # Freeze early layers
    for param in list(model.parameters())[:-20]:
        param.requires_grad = False
    
    num_ftrs = model.classifier[1].in_features
    model.classifier = nn.Sequential(
        nn.Dropout(0.3),
        nn.Linear(num_ftrs, num_classes)
    )
    
    return model.to(device)

# =============================================================================
# TRAINING
# =============================================================================
def train_model(model, dataloaders, dataset_sizes, criterion, optimizer, scheduler, device):
    best_model_wts = copy.deepcopy(model.state_dict())
    best_acc = 0.0
    patience = 0
    
    for epoch in range(NUM_EPOCHS):
        print(f'\nEpoch {epoch+1}/{NUM_EPOCHS}')
        print('-' * 30)
        
        for phase in ['Training', 'Validation']:
            model.train() if phase == 'Training' else model.eval()
            
            running_loss = 0.0
            running_corrects = 0
            
            for inputs, labels in dataloaders[phase]:
                inputs, labels = inputs.to(device), labels.to(device)
                optimizer.zero_grad()
                
                with torch.set_grad_enabled(phase == 'Training'):
                    outputs = model(inputs)
                    _, preds = torch.max(outputs, 1)
                    loss = criterion(outputs, labels)
                    
                    if phase == 'Training':
                        loss.backward()
                        optimizer.step()
                        scheduler.step()
                
                running_loss += loss.item() * inputs.size(0)
                running_corrects += torch.sum(preds == labels.data)
            
            epoch_loss = running_loss / dataset_sizes[phase]
            epoch_acc = running_corrects.double() / dataset_sizes[phase]
            
            print(f'{phase:10} Loss: {epoch_loss:.4f} | Acc: {epoch_acc*100:.2f}%')
            
            if phase == 'Validation':
                if epoch_acc > best_acc:
                    best_acc = epoch_acc
                    best_model_wts = copy.deepcopy(model.state_dict())
                    patience = 0
                    print(f'  ✓ New best: {best_acc*100:.2f}%')
                else:
                    patience += 1
                    if patience >= EARLY_STOP_PATIENCE:
                        print('\nEarly stopping!')
                        model.load_state_dict(best_model_wts)
                        return model, best_acc
        
        print(f'Cooling {COOLING_PAUSE}s...')
        time.sleep(COOLING_PAUSE)
    
    model.load_state_dict(best_model_wts)
    return model, best_acc

# =============================================================================
# TEST
# =============================================================================
def test_model(model, dataloader, dataset_size, class_names, device):
    model.eval()
    correct = 0
    class_correct = {c: 0 for c in class_names}
    class_total = {c: 0 for c in class_names}
    
    with torch.no_grad():
        for inputs, labels in dataloader:
            inputs, labels = inputs.to(device), labels.to(device)
            outputs = model(inputs)
            _, preds = torch.max(outputs, 1)
            correct += (preds == labels).sum().item()
            
            for i in range(len(labels)):
                label = class_names[labels[i]]
                class_total[label] += 1
                if preds[i] == labels[i]:
                    class_correct[label] += 1
    
    acc = correct / dataset_size
    print(f'\n{"="*40}')
    print(f'TEST ACCURACY: {acc*100:.2f}%')
    print(f'{"="*40}')
    for c in class_names:
        if class_total[c] > 0:
            print(f'  {c}: {class_correct[c]/class_total[c]*100:.1f}%')
    return acc

# =============================================================================
# MAIN
# =============================================================================
def main():
    print('='*50)
    print('BRAIN TUMOR CLASSIFICATION')
    print('Lightweight + High Accuracy')
    print('='*50)
    
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f'Device: {device}')
    
    dataloaders, sizes, classes, weights = load_data()
    print(f'Classes: {classes}')
    print(f'Training: {sizes["Training"]} | Val: {sizes["Validation"]} | Test: {sizes["Testing"]}')
    
    model = create_model(len(classes), device)
    
    # Focal Loss for better precision
    criterion = FocalLoss(alpha=weights.to(device), gamma=2.0)
    
    optimizer = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=LEARNING_RATE)
    scheduler = OneCycleLR(optimizer, max_lr=LEARNING_RATE, steps_per_epoch=len(dataloaders['Training']), epochs=NUM_EPOCHS)
    
    model, best_acc = train_model(model, dataloaders, sizes, criterion, optimizer, scheduler, device)
    test_acc = test_model(model, dataloaders['Testing'], sizes['Testing'], classes, device)
    
    # Save
    torch.save(model.state_dict(), os.path.join(MODEL_SAVE_DIR, 'classifier_real.pth'))
    with open(os.path.join(MODEL_SAVE_DIR, 'classes.txt'), 'w') as f:
        f.write('\n'.join(classes))
    
    print(f'\n✓ Model saved!')
    print(f'  Val: {best_acc*100:.2f}% | Test: {test_acc*100:.2f}%')

if __name__ == '__main__':
    main()
