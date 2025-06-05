trigger UserStoryTrigger on User_Story__c (after insert, after update) {
    List<User_Story_Task__c> tasksToInsert = new List<User_Story_Task__c>();
    Set<Id> userStoryIdsToUpdate = new Set<Id>();

    for (User_Story__c userStory : Trigger.new) {
        if (userStory.Design_this_story__c != null && 
            (Trigger.isInsert || userStory.Design_this_story__c != Trigger.oldMap.get(userStory.Id).Design_this_story__c)) {
            userStoryIdsToUpdate.add(userStory.Id);
        }
    }

    if (!userStoryIdsToUpdate.isEmpty()) {
        // Delete existing tasks to prevent duplication
        List<User_Story_Task__c> tasksToDelete = [SELECT Id FROM User_Story_Task__c WHERE User_Story__c IN :userStoryIdsToUpdate];
        if (!tasksToDelete.isEmpty()) {
            delete tasksToDelete;
        }

        for (User_Story__c userStory : [SELECT Id, Design_this_story__c FROM User_Story__c WHERE Id IN :userStoryIdsToUpdate]) {
            if (userStory.Design_this_story__c != null) {
                // Remove HTML tags before processing
                String cleanText = userStory.Design_this_story__c.replaceAll('<.*?>', '').trim();

                // Split based on numbered bullets (1., 2., etc.)
                List<String> taskDescriptions = cleanText.split('\\s*\\d+\\.\\s+');

                Integer taskOrder = 1;  // Initialize a counter for task order as Integer

                for (String taskDescription : taskDescriptions) {
                    taskDescription = taskDescription.trim();

                    // Skip empty entries
                    if (!String.isEmpty(taskDescription)) {
                        // Split by hyphen
                        List<String> parts = taskDescription.split('----');
                        User_Story_Task__c task = new User_Story_Task__c();
                        task.User_Story__c = userStory.Id;

                        // Set Task_Description and Type_of_Task based on hyphen presence
                        if (parts.size() >= 2) {
                            task.Task_Description__c = parts[0].trim();  // First part in Task_Description
                            task.Type_of_Task__c = parts[1].trim();      // Second part in Type_of_Task
                        } else {
                            task.Task_Description__c = taskDescription;  // No hyphen case
                        }

                        // Set the Task_Order_number__c field as a number
                        task.Task_Order_number__c = taskOrder;  // Assign the task order number
                        tasksToInsert.add(task);

                        taskOrder++;  // Increment the task order number
                    }
                }
            }
        }

        // Insert new tasks
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}